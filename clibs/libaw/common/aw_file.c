 

#include "aw_file.h"
#include "aw_utils.h"
#include <errno.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <dirent.h>

extern int8_t aw_is_file_exist(const char *file_path){
    FILE *file = fopen(file_path, "r");
    if(file == NULL){
        if (errno == ENOENT) {
            return 0;
        }else{
            AWLog("file open error errno=%d", errno);
            return -1;
        }
    }
    fclose(file);
    return 1;
}

extern size_t aw_file_size(const char *file_path){
    FILE * file = fopen(file_path, "r");
    if (file) {
        fseek(file, 0, SEEK_END);
        size_t file_size = ftell(file);
        fclose(file);
        return file_size;
    }
    return 0;
}

extern int8_t aw_remove_file(const char *file_path){
    if (aw_is_file_exist(file_path)) {
        return (int8_t)remove(file_path) == 0;
    }
    return 1;
}

extern int8_t aw_remove_dir(const char *file_dir){
    DIR *dp = NULL;
    struct dirent *entry = NULL;
    struct stat stat;
    if ((dp = opendir(file_dir)) == NULL) {
        return 0;
    }
    chdir (file_dir);
    while ((entry = readdir(dp)) != NULL)
    {
        lstat(entry->d_name, &stat);
        if (S_ISREG(stat.st_mode))
        {
            remove(entry->d_name);
        }
    }
    
    return 1;
}

extern aw_data *aw_read_data_from_file(const char *file_path){
    FILE * file = fopen(file_path, "r+");
    if (file) {
        size_t file_size = aw_file_size(file_path);
        aw_data *mp4_data = alloc_aw_data((int)file_size);
        size_t read_item_count = fread(mp4_data->data, file_size, 1, file);
        fclose(file);
        if (!read_item_count) {
            free_aw_data(&mp4_data);
            return NULL;
        }
        return mp4_data;
    }
    return NULL;
}

extern int8_t aw_write_data_to_file(const char *file_path, aw_data *data){
    FILE *file = fopen(file_path, "w");
    if (file) {
        size_t file_size = data->size;
        size_t write_item_count = fwrite(data->data, file_size, 1, file);
        fflush(file);
        fclose(file);
        return write_item_count != 0;
    }
    return 0;
}

extern void aw_test_file(const char *dir){
    char *short_name = "/tmp.t";
    size_t file_name_size = strlen(dir) + strlen(short_name) + 1;
    char *file_name = aw_alloc(file_name_size);
    memset(file_name, 0, file_name_size);
    memcpy(file_name, dir, strlen(dir));
    memcpy(file_name + strlen(dir), short_name, strlen(short_name));
    
    //??????????????????
    AWLog("1 file %s is exist(%d)", file_name, aw_is_file_exist(file_name));
    
    //????????????
    aw_data *awdata = alloc_aw_data(0);
    char *datastr = "nihao hahaha ??????";
    memcpy_aw_data(&awdata, datastr, (int32_t)strlen(datastr) + 1);
    
    if(aw_write_data_to_file(file_name, awdata)){
        AWLog("??????????????????");
    }else{
        AWLog("??????????????????");
    }
    free_aw_data(&awdata);
    //??????????????????
    AWLog("2 file %s is exist(%d)", file_name, aw_is_file_exist(file_name));
    AWLog("3 file %s size(%ld)", file_name, aw_file_size(file_name));
    
    //????????????
    aw_data *readdata = aw_read_data_from_file(file_name);
    if (readdata) {
        AWLog("?????????????????? %s", readdata->data);
        free_aw_data(&readdata);
    }else{
        AWLog("??????????????????");
    }
    
    //????????????
    if(aw_remove_file(file_name)){
        AWLog("??????????????????");
    }else{
        AWLog("??????????????????");
    }
    
}
