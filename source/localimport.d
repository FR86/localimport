module localimport;

/**
 * Check if string can be used as a straight module import.
 */
private template IsModuleImport(string import_) {
    enum IsModuleImport = __traits(compiles, { mixin("import ", import_, ";"); });
}

/**
 * Check if the requested symbol is found in the specified module.
 */
private template IsSymbolInModule(string module_, string symbol) {
    static if (IsModuleImport!module_) {
        enum import_ = module_ ~ ":" ~ symbol;
        enum IsSymbolInModule = __traits(compiles, {
                mixin("import ", import_, ";");
            });
    } else {
        enum IsSymbolInModule = false;
    }
}

/**
 * Used to generate useful error messages.
 */
private template failedSymbol(string symbol, string module_) {
    void failedSymbol(Args...)(auto ref Args args) {
        enum msg = "Symbol \"" ~ symbol ~ "\" not found in " ~ module_;
        version (LocalImportUnittest) {
            throw new Exception(msg);
        } else {
            static assert(0, msg);
        }
    }
}

/**
 * Here the magic happens.
 * Recursively descends along the dots in usage until it can resolve an imported
 * module or symbol from module or reaches the end of the dot chain.
 */
private struct FromImpl(string module_) {
    // opDispatch handles access to missing members of an object. 
    template opDispatch(string symbol) {
        // statically check if symbol is in given module
        static if (IsSymbolInModule!(module_, symbol)) {
            // Symbol import: emit module import and alias opDispatch to
            // the symbol.
            mixin("import ", module_, "; alias opDispatch = ", symbol, ";");
        } else { // symbol not in module
            static if (module_.length == 0) {
                // module string is of zero length, import of a top level module.
                enum opDispatch = FromImpl!(symbol)();
            } else {
                // Check if we have a full module import.
                enum import_ = module_ ~ "." ~ symbol;
                static if (IsModuleImport!import_) {
                    // full module import
                    enum opDispatch = FromImpl!(import_)();
                } else {
                    // failed symbol import as well as full module import and
                    // the last symbol is of nonzero length.
                    // -> resolution failed!
                    alias opDispatch = failedSymbol!(symbol, module_);
                }
            }
        }
    }
}

/**
 * Used as entry point for local imports.
 */
enum from = FromImpl!null();

/**
 * Test things that should work.
 */
unittest {
    // use a function from standard library directly.
    from.std.stdio.writeln("Hallo");
    // assign something from standard library to a local variable.
    auto _ = from.std.datetime.stopwatch.AutoStart.yes;
}

/**
 * Test that calling a nonexistent function with a string throws with a useful
 * message.
 */
unittest {
    import std.algorithm.searching : canFind;

    auto throws = false;
    uint containsInfo;
    try {
        from.std.stdio.thisFunctionDoesNotExist("Hallo");
    } catch (Exception ex) {
        throws = true;
        containsInfo = canFind(ex.msg, "stdio", "thisFunctionDoesNotExist");
    }

    assert(throws);
    assert(containsInfo == 2);
}

/**
 * Test that calling a nonexistent function with a number throws with a useful 
 * message.
 */
unittest {
    import std.algorithm.searching : canFind;

    auto throws = false;
    uint containsInfo;
    try {
        from.std.stdio.thisFunctionDoesNotExist(42);
        throws = false;
    } catch (Exception ex) {
        throws = true;
        containsInfo = canFind(ex.msg, "stdio", "thisFunctionDoesNotExist");
    }

    assert(throws);
    assert(containsInfo == 2);
}
