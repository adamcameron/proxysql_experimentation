component {

    setsettings()
    loadDatasources()
    loadMappings()

    private void function setSettings() {
        this.name = "proxysql"
        this.localMode = "modern"
    }

    private void function loadDataSources() {
        this.datasources[this.name] = {
            type = "mysql",
            host = "proxysql.backend",
            port = 6033,
            database = "proxysql_db",
            username = "proxysql_db_user",
            password = server.system.environment.MARIADB_PASSWORD,
            custom = {
                useUnicode = true,
                characterEncoding = "UTF-8",
                noAccessToProcedureBodies = true
            }
        }

        this.datasource = this.name
    }

    private void function loadMappings() {
    }
}
