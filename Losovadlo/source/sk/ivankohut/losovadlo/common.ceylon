import ceylon.file {
	parsePath,
	Resource
}

"Rozhranie pre triedy, ktore poskytuju T cez metodu, lebo nemozu z neho dedit."
interface Provider<T> {
	shared formal <T> get();
}

class ResultsResourceProvider() satisfies Provider<Resource> {
	shared actual Resource get() => parsePath("results.txt").resource;
}

void clearScreen() {
	for (i in 1..200) {
		print("***************************************************************************");
	}
	print("");
	print("");
}