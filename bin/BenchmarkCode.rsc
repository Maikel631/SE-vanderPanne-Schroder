module BenchmarkCode

import util::Benchmark;

/* Wrapper for the util::Benchmark method. */
public num benchmarkCode(void() func) {
	miliSec = benchmark(("test": func))["test"];
	return miliSec / 1000;
}