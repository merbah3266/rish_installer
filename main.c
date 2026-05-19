#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <dirent.h>
#include <signal.h>
#include <stdarg.h>
#include <curl/curl.h>
#include "miniz.h"

char *BIN = NULL;
char RISH_PATH[512];
char DEX_PATH[512];
char TMP_SUBDIR[256];
int SILENT_MODE = 0;
int ACTION_INSTALL = 1;
int ACTION_REINSTALL = 0;

const char *C0="", *CR="", *CG="", *CY="", *CB="", *CC="";

void setup_colors() {
    if (isatty(1)) {
        C0="\033[0m"; CR="\033[1;31m"; CG="\033[1;32m"; 
        CY="\033[1;33m"; CB="\033[1;34m"; CC="\033[1;36m";
    }
}

void cancel(const char *fmt, ...) { va_list args; va_start(args, fmt); printf("%s[!]%s ", CY, C0); vprintf(fmt, args); printf("\n"); va_end(args); exit(0); }
void msg(const char *fmt, ...) { if(!SILENT_MODE) { va_list args; va_start(args, fmt); printf("%s[i]%s ", CB, C0); vprintf(fmt, args); printf("\n"); va_end(args); } }
void ok(const char *fmt, ...) { if(!SILENT_MODE) { va_list args; va_start(args, fmt); printf("%s[+]%s ", CG, C0); vprintf(fmt, args); printf("\n"); va_end(args); } }
void warn(const char *fmt, ...) { if(!SILENT_MODE) { va_list args; va_start(args, fmt); printf("%s[!]%s ", CY, C0); vprintf(fmt, args); printf("\n"); va_end(args); } }
void err(const char *fmt, ...) { va_list args; va_start(args, fmt); printf("%s[x]%s ", CR, C0); vprintf(fmt, args); printf("\n"); va_end(args); exit(1); }
void step(const char *fmt, ...) { if(!SILENT_MODE) { va_list args; va_start(args, fmt); printf("%s==>%s ", CC, C0); vprintf(fmt, args); printf("\n"); va_end(args); } }

void cleanup() {
    if (strlen(TMP_SUBDIR) > 0) {
        char cmd[512];
        snprintf(cmd, sizeof(cmd), "rm -rf %s", TMP_SUBDIR);
        system(cmd);
    }
}

void on_cancel(int sig) {
    printf("\n%s[!]%s Operation cancelled by user.\n", CY, C0);
    cleanup();
    exit(1);
}

void read_input(char *buffer, int size) {
    static FILE *tty = NULL;
    if (!tty) {
        tty = fopen("/dev/tty", "r");
        if (!tty) {
            if (isatty(fileno(stdin))) {
                tty = stdin;
            }
        }
    }
    
    fflush(stdout);
    
    if (tty) {
        if (fgets(buffer, size, tty)) {
            buffer[strcspn(buffer, "\n")] = 0;
        } else {
            buffer[0] = '\0';
        }
    } else {
        buffer[0] = '\0';
    }
}

char* str_replace(const char* src, const char* find, const char* replace) {
    size_t src_len = strlen(src), find_len = strlen(find), replace_len = strlen(replace);
    size_t count = 0;
    const char *p = src;
    while ((p = strstr(p, find))) { count++; p += find_len; }
    
    size_t result_len = src_len + count * (replace_len - find_len);
    char *result = malloc(result_len + 1);
    char *dst = result;
    p = src;
    while (*p) {
        if (strstr(p, find) == p) {
            memcpy(dst, replace, replace_len);
            dst += replace_len; p += find_len;
        } else {
            *dst++ = *p++;
        }
    }
    *dst = '\0';
    return result;
}

void process_rish_file(const char* in_path, const char* out_path, const char* sh_path, const char* pkg) {
    FILE *in = fopen(in_path, "r");
    if (!in) err("Failed to open extracted rish");
    
    FILE *out = fopen(out_path, "w");
    if (!out) err("Failed to create temp rish");
    
    fprintf(out, "#!%s\n", sh_path);
    
    char line[2048];
    while (fgets(line, sizeof(line), in)) {
        if (line[0] != '#') {
            fputs(line, out);
        }
    }
    fclose(in);
    fclose(out);
    
    in = fopen(out_path, "r");
    fseek(in, 0, SEEK_END); long fsize = ftell(in); fseek(in, 0, SEEK_SET);
    char *content = malloc(fsize + 1);
    fread(content, 1, fsize, in); content[fsize] = 0;
    fclose(in);
    
    char *replaced = str_replace(content, "PKG", pkg);
    free(content);
    
    out = fopen(out_path, "w");
    fputs(replaced, out);
    fclose(out);
    free(replaced);
}

size_t write_file_cb(void* ptr, size_t size, size_t nmemb, FILE* stream) {
    return fwrite(ptr, size, nmemb, stream);
}

struct MemoryStruct {
    char *memory;
    size_t size;
};

size_t write_mem_cb(void* contents, size_t size, size_t nmemb, void* userp) {
    size_t realsize = size * nmemb;
    struct MemoryStruct *mem = (struct MemoryStruct *)userp;
    char *ptr = realloc(mem->memory, mem->size + realsize + 1);
    if(!ptr) return 0;
    mem->memory = ptr;
    memcpy(&(mem->memory[mem->size]), contents, realsize);
    mem->size += realsize;
    mem->memory[mem->size] = 0;
    return realsize;
}

void download_file(const char* url, const char* out_path) {
    CURL *curl = curl_easy_init();
    if(!curl) err("Curl init failed");
    FILE *fp = fopen(out_path, "wb");
    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_file_cb);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
    CURLcode res = curl_easy_perform(curl);
    curl_easy_cleanup(curl);
    fclose(fp);
    if(res != CURLE_OK) err("Download failed: %s", curl_easy_strerror(res));
}

char* fetch_github_url(const char* repo) {
    char api_url[256];
    snprintf(api_url, sizeof(api_url), "https://api.github.com/repos/%s/releases/latest", repo);
    
    struct MemoryStruct chunk;
    chunk.memory = malloc(1); chunk.size = 0;
    
    CURL *curl = curl_easy_init();
    curl_easy_setopt(curl, CURLOPT_URL, api_url);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_mem_cb);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void*)&chunk);
    curl_easy_setopt(curl, CURLOPT_USERAGENT, "rish-installer-c");
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
    CURLcode res = curl_easy_perform(curl);
    curl_easy_cleanup(curl);
    
    if(res != CURLE_OK) err("API fetch failed");
    
    char *apk_url = NULL;
    char *token = strtok(chunk.memory, "\"");
    while (token != NULL) {
        if (strstr(token, ".apk") != NULL && strstr(token, "browser_download_url") == NULL) {
            if (strstr(token, "https://") != NULL) {
                apk_url = strdup(token);
                break;
            }
        }
        token = strtok(NULL, "\"");
    }
    free(chunk.memory);
    if(!apk_url) err("APK URL not found in API response");
    return apk_url;
}

void extract_apk(const char* apk_path) {
    mz_zip_archive zip_archive;
    memset(&zip_archive, 0, sizeof(zip_archive));
    
    if (!mz_zip_reader_init_file(&zip_archive, apk_path, 0)) 
        err("Miniz: Failed to open APK");

    int rish_idx = mz_zip_reader_locate_file(&zip_archive, "assets/rish", NULL, 0);
    int dex_idx = mz_zip_reader_locate_file(&zip_archive, "assets/rish_shizuku.dex", NULL, 0);

    if (rish_idx < 0 || dex_idx < 0) 
        err("rish or dex not found inside APK");

    char out_rish[512], out_dex[512];
    snprintf(out_rish, sizeof(out_rish), "%s/rish", TMP_SUBDIR);
    snprintf(out_dex, sizeof(out_dex), "%s/rish_shizuku.dex", TMP_SUBDIR);

    if (!mz_zip_reader_extract_to_file(&zip_archive, rish_idx, out_rish, 0))
        err("Failed to extract rish");
    if (!mz_zip_reader_extract_to_file(&zip_archive, dex_idx, out_dex, 0))
        err("Failed to extract dex");

    mz_zip_reader_end(&zip_archive);
}

void install_files(const char* src_rish, const char* src_dex) {
    int success = 0;
    
    if (access(BIN, W_OK) == 0) {
        char cmd_install[1024];
        snprintf(cmd_install, sizeof(cmd_install), "install -m 755 %s %s && install -m 400 %s %s", src_rish, RISH_PATH, src_dex, DEX_PATH);
        if (system(cmd_install) == 0) {
            ok("Installed to bin (%s)", BIN);
            char sym1[512], sym2[512];
            const char *home = getenv("HOME");
            if(home) {
                snprintf(sym1, sizeof(sym1), "%s/rish", home);
                snprintf(sym2, sizeof(sym2), "%s/rish_shizuku.dex", home);
                unlink(sym1); unlink(sym2);
                symlink(RISH_PATH, sym1);
                symlink(DEX_PATH, sym2);
            }
            success = 1;
        }
    }
    
    if (!success) {
        const char *home = getenv("HOME");
        if (home) {
            char home_rish[512], home_dex[512];
            snprintf(home_rish, sizeof(home_rish), "%s/rish", home);
            snprintf(home_dex, sizeof(home_dex), "%s/rish_shizuku.dex", home);
            
            char cmd_install[1024];
            snprintf(cmd_install, sizeof(cmd_install), "install -m 755 %s %s && install -m 400 %s %s", src_rish, home_rish, src_dex, home_dex);
            if (system(cmd_install) == 0) {
                ok("Installed to Home");
                success = 1;
            }
        }
    }

    if (!success) err("Installation failed");
    else if(SILENT_MODE) printf("%s[+]%s Success: rish installed.\n", CG, C0);
    else ok("Setup complete. Run 'rish' or '~/rish'");
}

int main(int argc, char *argv[]) {
    setup_colors();
    
    if (getuid() == 0) {
        err("Please do not run this as root!");
    }

    atexit(cleanup);
    signal(SIGINT, on_cancel);
    
    char *SOURCE_MODE = "default";
    char *SOURCE_PATH = NULL;
    int SOURCE_PROVIDED = 0;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--uninstall") == 0) { ACTION_INSTALL = 0; }
        else if (strcmp(argv[i], "--reinstall") == 0) { ACTION_REINSTALL = 1; }
        else if (strcmp(argv[i], "--silent") == 0) { SILENT_MODE = 1; }
        else if (strncmp(argv[i], "--source=", 9) == 0) { SOURCE_MODE = &argv[i][9]; SOURCE_PROVIDED = 1; }
        else if (strcmp(argv[i], "--source") == 0 && i+1 < argc) { SOURCE_MODE = argv[++i]; SOURCE_PROVIDED = 1; }
        else if (strncmp(argv[i], "--path=", 7) == 0) { SOURCE_PATH = &argv[i][7]; }
        else if (strcmp(argv[i], "--path") == 0 && i+1 < argc) { SOURCE_PATH = argv[++i]; }
    }
    
    const char *home = getenv("HOME");
    if (!home) home = "/data/local/tmp";
    
    char bash_path[256];
    FILE *fp = popen("command -v bash 2>/dev/null", "r");
    if (fp && fgets(bash_path, sizeof(bash_path), fp)) {
        bash_path[strcspn(bash_path, "\n")] = 0;
        char *last_slash = strrchr(bash_path, '/');
        if (last_slash) *last_slash = '\0';
        BIN = strdup(bash_path);
    } else {
        BIN = strdup("/system/bin");
    }
    if(fp) pclose(fp);

    snprintf(RISH_PATH, sizeof(RISH_PATH), "%s/rish", BIN);
    snprintf(DEX_PATH, sizeof(DEX_PATH), "%s/rish_shizuku.dex", BIN);
    
    if (!ACTION_INSTALL) {
        unlink(RISH_PATH); unlink(DEX_PATH);
        char tmp[512];
        snprintf(tmp, sizeof(tmp), "%s/rish", home); unlink(tmp);
        snprintf(tmp, sizeof(tmp), "%s/rish_shizuku.dex", home); unlink(tmp);
        ok("rish has been removed.");
        return 0;
    }
    
    const char *prefix = getenv("PREFIX");
    const char *pkg_path = prefix ? prefix : home;
    char PKG[256] = "unknown";
    if (strncmp(pkg_path, "/data/data/", 11) == 0) {
        sscanf(pkg_path + 11, "%[^/]", PKG);
    } else if (strncmp(pkg_path, "/data/user/", 11) == 0) {
        int uid; 
        sscanf(pkg_path + 11, "%*d/%[^/]", PKG);
    }
    if (strcmp(PKG, "unknown") == 0) err("Package detect failed");
    
    if (access(RISH_PATH, F_OK) != -1 && !ACTION_REINSTALL && !SILENT_MODE) {
        printf("%s[?]%s rish installed. Reinstall? [y/N]: ", CY, C0);
        char c_line[16] = {0};
        read_input(c_line, sizeof(c_line));
        if (c_line[0] == 'y' || c_line[0] == 'Y') ACTION_REINSTALL = 1;
        else cancel("Cancelled.");
    }
    
    if (!SILENT_MODE && !SOURCE_PROVIDED) {
        printf("\n%sSelect source:%s\n 1) Offline (Extract app)\n 2) RikkaApps/Shizuku\n 3) thedjchi/Shizuku\n 4) Custom Repo\n 5) Direct URL\n 6) Local APK\n", CB, C0);
        printf("Choice [1-6]: ");
        
        char choice_line[16] = {0};
        read_input(choice_line, sizeof(choice_line));
        int choice = atoi(choice_line);
        
        char input_buf[512] = {0};
        switch(choice) {
            case 1: SOURCE_MODE = "local_app"; break;
            case 2: SOURCE_MODE = "default"; break;
            case 3: SOURCE_MODE = "thedjchi"; break;
            case 4: 
                SOURCE_MODE = "custom_repo"; 
                printf("Repo (user/repo): "); 
                read_input(input_buf, sizeof(input_buf));
                SOURCE_PATH = strdup(input_buf); 
                break;
            case 5: 
                SOURCE_MODE = "custom_url"; 
                printf("URL: "); 
                read_input(input_buf, sizeof(input_buf));
                SOURCE_PATH = strdup(input_buf); 
                break;
            case 6: 
                SOURCE_MODE = "local_file"; 
                printf("Path: "); 
                read_input(input_buf, sizeof(input_buf));
                SOURCE_PATH = strdup(input_buf); 
                break;
            default: cancel("Invalid choice. Cancelled.");
        }
    }

    if (SILENT_MODE) ok("Starting silent rish installation...");
    
    snprintf(TMP_SUBDIR, sizeof(TMP_SUBDIR), "%s/rish.%d", getenv("TMPDIR") ? getenv("TMPDIR") : "/tmp", rand());
    mkdir(TMP_SUBDIR, 0755);

    curl_global_init(CURL_GLOBAL_ALL);

    char APK_PATH[512];
    snprintf(APK_PATH, sizeof(APK_PATH), "%s/app.apk", TMP_SUBDIR);
    int OFFLINE_OK = 0;
    
    if (strcmp(SOURCE_MODE, "local_app") == 0 || strcmp(SOURCE_MODE, "default") == 0) {
        step("Offline attempt...");
        char cmd[256], extracted_path[256] = {0};
        fp = popen("cmd package path moe.shizuku.privileged.api --user 0 2>/dev/null", "r");
        if (fp) {
            while (fgets(extracted_path, sizeof(extracted_path), fp)) {
                if (strncmp(extracted_path, "package:", 8) == 0) {
                    char *p = extracted_path + 8;
                    extracted_path[strcspn(extracted_path, "\n")] = 0;
                    if (access(p, F_OK) == 0) {
                        char cp_cmd[512]; snprintf(cp_cmd, sizeof(cp_cmd), "cp %s %s", p, APK_PATH);
                        if(system(cp_cmd) == 0) { OFFLINE_OK = 1; ok("Local APK extracted"); break; }
                    }
                }
            }
            pclose(fp);
        }
        if (!OFFLINE_OK && strcmp(SOURCE_MODE, "local_app") == 0) cancel("Shizuku not found locally. Cancelled.");
        else if (!OFFLINE_OK) warn("Offline failed, falling back online...");
    }
    
    if (!OFFLINE_OK) {
        if (strcmp(SOURCE_MODE, "local_file") == 0) {
            step("Using local file");
            if (!SOURCE_PATH || access(SOURCE_PATH, F_OK) != 0) cancel("File not found. Cancelled.");
            char cp_cmd[512]; snprintf(cp_cmd, sizeof(cp_cmd), "cp %s %s", SOURCE_PATH, APK_PATH);
            if(system(cp_cmd) != 0) cancel("Copy failed. Cancelled.");
            ok("Copied");
        } 
        else if (strcmp(SOURCE_MODE, "custom_url") == 0) {
            step("Downloading from URL");
            if (!SOURCE_PATH) cancel("No URL provided. Cancelled.");
            download_file(SOURCE_PATH, APK_PATH);
            ok("Downloaded");
        }
        else if (strcmp(SOURCE_MODE, "default") == 0 || strcmp(SOURCE_MODE, "thedjchi") == 0 || strcmp(SOURCE_MODE, "custom_repo") == 0) {
            const char *REPO = NULL;
            if (strcmp(SOURCE_MODE, "default") == 0) REPO = "RikkaApps/Shizuku";
            else if (strcmp(SOURCE_MODE, "thedjchi") == 0) REPO = "thedjchi/Shizuku";
            else REPO = SOURCE_PATH;
            
            if (!REPO) cancel("No repo provided. Cancelled.");
            step("Fetching from %s...", REPO);
            
            char *url = fetch_github_url(REPO);
            step("Downloading APK...");
            download_file(url, APK_PATH);
            free(url);
            ok("Downloaded");
        } else {
            cancel("Invalid source. Cancelled.");
        }
    }
    
    step("Extracting...");
    extract_apk(APK_PATH);
    
    const char *sh_path = getenv("SHELL");
    if (!sh_path) sh_path = "/system/bin/sh";

    char extracted_rish[512], final_rish[512];
    snprintf(extracted_rish, sizeof(extracted_rish), "%s/rish", TMP_SUBDIR);
    snprintf(final_rish, sizeof(final_rish), "%s/rish_final", TMP_SUBDIR);
    
    process_rish_file(extracted_rish, final_rish, sh_path, PKG);
    
    step("Installing...");
    char final_dex[512];
    snprintf(final_dex, sizeof(final_dex), "%s/rish_shizuku.dex", TMP_SUBDIR);
    install_files(final_rish, final_dex);

    curl_global_cleanup();
    return 0;
}
