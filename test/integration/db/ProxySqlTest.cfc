import testbox.system.BaseSpec

component extends=BaseSpec {

    function run() {
        describe("Tests ProxySQL", () => {
            it("hits DB1 for queries of test_db1_only", () => {
                result = queryExecute("SELECT * FROM test_db1_only ORDER BY id")
                expect(result).toHaveLength(2)
                expect(result.filter((row) => row.value CONTAINS "DB1 only")).toHaveLength(2)
            })
            it("hits DB2 for queries of test_db2_only", () => {
                result = queryExecute("SELECT * FROM test_db2_only ORDER BY id")
                expect(result).toHaveLength(2)
                expect(result.filter((row) => row.value CONTAINS "DB2 only")).toHaveLength(2)
            })
            it("hits DB1 for other queries", () => {
                result = queryExecute("SELECT * FROM test_both ORDER BY id")
                expect(result).toHaveLength(2)
                expect(result.filter((row) => row.value CONTAINS "DB1 instance")).toHaveLength(2)
            })
        })
    }
}
