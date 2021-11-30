#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include "fimDB.hpp"

#ifndef _FIMDB_HELPERS_MOCK_H_
#define _FIMDB_HELPERS_MOCK_H_


namespace FIMDBHelpersUTInterface {

#ifndef WIN32

    void initDB(unsigned int sync_interval, unsigned int file_limit,
                            fim_sync_callback_t sync_callback, logging_callback_t logCallback,
                            std::shared_ptr<DBSync>handler_DBSync, std::shared_ptr<RemoteSync>handler_RSync);
#else

    void initDB(unsigned int sync_interval, unsigned int file_limit, unsigned int registry_limit,
                             fim_sync_callback_t sync_callback, logging_callback_t logCallback,
                             std::shared_ptr<DBSync>handler_DBSync, std::shared_ptr<RemoteSync>handler_RSync);
#endif


    int removeFromDB(const std::string& tableName, const nlohmann::json& filter);

    int getCount(const std::string & tableName, int & count);

    int insertItem(const std::string & tableName, const nlohmann::json & item);

    int updateItem(const std::string & tableName, const nlohmann::json & item);

    int getDBItem(nlohmann::json & item, const nlohmann::json & query);
}

#endif //_FIMDBHELPER_H
