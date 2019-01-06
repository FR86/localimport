localimport
====

D import idiom originally described by Daniel Nielsen, see [this](https://dlang.org/blog/2017/02/13/a-new-import-idiom/) blog post. Later refined by Dgame, see [here](https://forum.dlang.org/post/debrounbfusnlfejxnuq@forum.dlang.org).

I basically moved this into a module and added some tests.

```D
import localimport;

void main() {
    from.std.stdio.writeln("Hallo");
    auto _ = from.std.datetime.stopwatch.AutoStart.yes;
    from.std.stdio.thisFunctionDoesNotExist("Hallo");
    from.std.stdio.thisFunctionDoesNotExist(42);
}
```