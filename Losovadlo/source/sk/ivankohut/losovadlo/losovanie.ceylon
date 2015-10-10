import ceylon.collection {
	HashMap,
	MutableMap
}
import ceylon.file {
	Nil,
	File,
	Directory,
	Resource
}
import ceylon.language {
	Map
}

import java.util {
	Random
}

class Losovac(shared String name) {
	shared actual String string => name;
}

interface LosovacChooser {
	shared formal Losovac choose({Losovac*} losovaci);
}

class Losovadlo([Losovac,Losovac+] losovaci, LosovacChooser nextLosovacChooser) {
	
	MutableMap<Losovac,Losovac> result;
	variable Losovac? nextLosovacOption;

	if (losovaci.size == 2) {
		result = HashMap{entries = {losovaci[0] -> losovaci[1], losovaci[1] -> losovaci[0]};};
		nextLosovacOption = null;
	} else {
		result = HashMap<Losovac,Losovac>();
		nextLosovacOption = nextLosovacChooser.choose(losovaci);
	}
	
	shared [Losovac, Losovac[]]? getOptions() {
		if (exists nextLosovac = nextLosovacOption) {
			value availableLosovaci = losovaci.filter((Losovac elem) => !result.items.contains(elem) && elem != nextLosovac);
			value rozhadzaniLosovaci = availableLosovaci.sort((Losovac x, Losovac y) => Random().nextBoolean() then larger else smaller);
			return [nextLosovac, rozhadzaniLosovaci];
		} else {
			return null;
		}
	}
	
	shared void setSelection(Losovac selected) {
		value nextLosovac = nextLosovacOption;
		switch (nextLosovac) 
			case (is Null) { throw Exception("Losovanie je uz uzavrete."); }
			case (is Losovac) { 
				result.put(nextLosovac, selected);
				value undecidedLosovaci = losovaci.filter((Losovac element) => !result.keys.contains(element));
				//assert (is {Losovac+} undecidedLosovaci);
				if (undecidedLosovaci.size > 2) {
					nextLosovacOption = nextLosovacChooser.choose(undecidedLosovaci);
				} else if (undecidedLosovaci.size == 2) {
					value availableLosovaci = losovaci.filter((Losovac elem) => !result.items.contains(elem));

					value undecidedLosovac1 = undecidedLosovaci.first else nothing;
					value undecidedLosovac2 = undecidedLosovaci.rest.first else nothing;
					//assert (exists undecidedLosovac2 = undecidedLosovaci.rest.first);
					assert (exists availableLosovac1 = availableLosovaci.first);
					assert (exists availableLosovac2 = availableLosovaci.rest.first);

					if (undecidedLosovac1 == availableLosovac1 || undecidedLosovac2 == availableLosovac2) {
						result.put(undecidedLosovac1, availableLosovac2);
						result.put(undecidedLosovac2, availableLosovac1);
						nextLosovacOption = null;
					} else if (undecidedLosovac1 == availableLosovac2 || undecidedLosovac2 == availableLosovac1) {
						result.put(undecidedLosovac1, availableLosovac1);
						result.put(undecidedLosovac2, availableLosovac2);
						nextLosovacOption = null;
					} else {
						nextLosovacOption = nextLosovacChooser.choose(undecidedLosovaci);
					}
				} else if (undecidedLosovaci.size == 1) {
					assert (exists lastAvailableLosovac = losovaci.find((Losovac elem) => !result.items.contains(elem)));
					result.put(undecidedLosovaci.first else nothing, lastAvailableLosovac);
					nextLosovacOption = null;
				} else {
					throw Exception("Illegal state");
				}
			}
	}
	
	shared Map<Losovac,Losovac> getResults() {
		return result;
	}
	
	shared Boolean isFinished() {
		return getOptions() exists;
	}
}

object randomChooser satisfies LosovacChooser {
	shared actual Losovac choose({Losovac*} losovaci) {
		value randomIndex = Random().nextInt(losovaci.size);
		assert (exists randomLosovac = losovaci.sequence()[randomIndex]);
		return randomLosovac;
	}
}

Integer readNumberFromConsole(Integer maxValue) {
	while (true) {
		if (exists line = process.readLine(), exists vyber = parseInteger(line), vyber > 0 && vyber <= maxValue) {
			return vyber;
		} else {
			print("Nebolo vybrane cislo od 1 do ``maxValue``");
		}
	}
}

Resource getResultsResource() {
	return ResultsResourceProvider().get();
}


shared void runLosovanie() {
	
	[Losovac,Losovac+] losovaci = [
		Losovac("Mama"), Losovac("Oco"), Losovac("Ivan"), Losovac("Lenka"), 
		Losovac("Silvia"), Losovac("Beno"), Losovac("Maros"), Losovac("Majka"), Losovac("Ala")
	];
	
	if (is File|Directory dest = getResultsResource()) {
		print("Cielovy subor existuje. Koniec.");
		return;
	}
	
	value losovadlo = Losovadlo(losovaci, randomChooser);
	while (exists options = losovadlo.getOptions()) {
		print("Losovac: ``options[0]``");
		print("Moznosti: 1 .. ``options[1].size ``");
		value selection = options[1].get(readNumberFromConsole(options[1].size) - 1);
		assert (exists selection);
		losovadlo.setSelection(selection);
		print("Vybrana moznost: " + selection.string);
		process.readLine();
		clearScreen();
	}
	print("Koniec losovania.");
	
	value res = getResultsResource();
	switch (res) 
		case (is Nil) {
			value file = res.createFile();
			try (overWriter = file.Overwriter()) {
				for (a in losovadlo.getResults()) {
					overWriter.writeLine(a.key.string + ":" + a.item.string);
				}
			}
		}
		else {
			print("Vysledky nesmu existovat!");
		}
}

