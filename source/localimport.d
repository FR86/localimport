module localimport;
template IsModuleImport(string import_) {
    enum IsModuleImport = __traits(compiles, { mixin("import ", import_, ";"); });
}

template IsSymbolInModule(string module_, string symbol) {
    static if (IsModuleImport!module_) {
        enum import_ = module_ ~ ":" ~ symbol;
        enum IsSymbolInModule = __traits(compiles, {
                mixin("import ", import_, ";");
            });
    } else {
        enum IsSymbolInModule = false;
    }
}

template failedSymbol(string symbol, string module_) {

    auto failedSymbol(Args...)(auto ref Args args) {
        throw new Exception("Symbol \"" ~ symbol ~ "\" not found in " ~ module_);
    }
}

struct FromImpl(string module_) {
    template opDispatch(string symbol) {
        static if (IsSymbolInModule!(module_, symbol)) {
            mixin("import ", module_, "; alias opDispatch = ", symbol, ";");
        } else {
            static if (module_.length == 0) {
                enum opDispatch = FromImpl!(symbol)();
            } else {
                enum import_ = module_ ~ "." ~ symbol;
                static if (IsModuleImport!import_) {
                    enum opDispatch = FromImpl!(import_)();
                } else {
                    alias opDispatch = failedSymbol!(symbol, module_);
                }
            }
        }
    }
}

enum from = FromImpl!null();

unittest {
    auto throws = false;

    try {
        from.std.stdio.writeln("Hallo");
        auto _ = from.std.datetime.stopwatch.AutoStart.yes;
    } catch (Exception ex) {
        throws = true;
    }
    assert(!throws);

    throws = false;
    try {
        from.std.stdio.thisFunctionDoesNotExist("Hallo");
    } catch (Exception ex) {
        throws = true;
    }
    try {
        from.std.stdio.thisFunctionDoesNotExist(42);
        throws = false;
    } catch (Exception ex) {
        throws = true;
    }

    assert(throws);

}
