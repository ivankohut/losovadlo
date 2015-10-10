import ceylon.file {
	File,
	AbstractReader=Reader,
	Resource
}

interface Results {
	shared formal String vylosovany(String losovac);
}

class ReadableResults(Readable file) satisfies Results {
	shared actual String vylosovany(String losovac) {
		try (reader = file.Reader()) {
			while (exists line = reader.readLine()) {
				if (line.startsWith(losovac)) {
					value indexOfColon = line.firstIndexWhere((Character element) => element == ':') else nothing;
					return line.spanFrom(indexOfColon + 1);
				}
			}
			throw Exception("Zadany losovac nelosoval.");
		}
	}
}

interface ZaujemcaOVysledok {
	shared formal String meno();
	shared formal void potvrdOboznamenieSa(String vylosovany);
}

class CliZaujemcaOVysledok() satisfies ZaujemcaOVysledok {
	
	shared actual String meno() {
		print("Zadaj hladane meno:");
		assert (exists requestedName = process.readLine());
		return requestedName;
	}
	
	shared actual void potvrdOboznamenieSa(String vylosovany) {
		print(vylosovany);
		print("Koniec.");
		process.readLine();
		clearScreen();
	}
}

interface Readable {
	shared formal class Reader(String? encoding=null) satisfies AbstractReader {}
}

class FileResourceReadable(Provider<Resource> res) satisfies Readable {
	
	shared actual class Reader(String? encoding) extends super.Reader(encoding) {
		
		AbstractReader underlying {
			value resource = res.get();
			switch (resource) 
			case (is File) {
				return resource.Reader();
			} else {
				throw Exception("Vysledky losovania neboli najdene.");
			} 
		}
		
		shared actual void close() => underlying.close();
		shared actual Byte[] readBytes(Integer max) => underlying.readBytes(max);
		shared actual String? readLine() => underlying.readLine();
	}
}

class OboznamenieSaZVysledkom(ZaujemcaOVysledok requester, Results results) {
	shared void execute() {
		requester.potvrdOboznamenieSa(results.vylosovany(requester.meno()));
	}
}

shared void loadLosovacAssignment() {
	OboznamenieSaZVysledkom(
		CliZaujemcaOVysledok(), 
		ReadableResults(
			FileResourceReadable(
				ResultsResourceProvider()
			)
		)
	).execute();
}
