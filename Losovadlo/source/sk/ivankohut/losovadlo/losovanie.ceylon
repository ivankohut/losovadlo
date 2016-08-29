import ceylon.collection {
	HashMap
}
import ceylon.file {
	Nil,
	Resource
}
import ceylon.language {
	Map
}

import java.util {
	Random
}

/**
 * Entry point.
 */
shared void runLosovanie() {

	Losovac createLosovac(String name) => FirstChoosingLosovac(name);

	[Losovac,Losovac+] losovaci = [
		createLosovac("Ala"), * ["Mama", "Oco", "Ivan", "Lenka", "Silvia", "Beno", "Maros", "Majka"].collect((name) => createLosovac(name))
	];
	FileWriteableResults(ResultsResourceProvider()).write(Losovanie(losovaci, randomChooser));
}

interface LosovacChooser {
	shared formal Losovac choose({Losovac*} losovaci);
}

class Losovadlo([Losovac,Losovac+] losovaci, LosovacChooser nextLosovacChooser) {

	value [resultX, nextLosovacOptionValue] = if (losovaci.size == 2) then
		[HashMap{entries = {losovaci[0] -> losovaci[1], losovaci[1] -> losovaci[0]};}, null]
	else
		[HashMap<Losovac,Losovac>(), nextLosovacChooser.choose(losovaci)];


	value result = resultX; // compiler bug workaround

	variable value nextLosovacOption = nextLosovacOptionValue;


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

class NaturalNumberFromConsole(Integer maxValue) satisfies Provider<Integer> {
	shared actual Integer get() {
		while (true) {
			if (exists line = process.readLine(), exists vyber = parseInteger(line), vyber > 0 && vyber <= maxValue) {
				return vyber;
			} else {
				print("Nebolo vybrane cislo od 1 do ``maxValue``");
			}
		}
	}
}

Resource getResultsResource() {
	return ResultsResourceProvider().get();
}

class Losovanie([Losovac, Losovac+] losovaci, LosovacChooser chooser) satisfies Iterable<[Named,Named]> {
	// TODO
	shared actual Iterator<Named[2]> iterator() {
		value losovadlo = Losovadlo(losovaci, randomChooser);
		while (exists options = losovadlo.getOptions()) {
			value selection = options[1].get(options[0].choose(options[1].size) - 1);
			assert (exists selection);
			losovadlo.setSelection(selection);
			options[0].acquaintWithSelection(selection);
		}
		print("Koniec losovania.");
		return losovadlo.getResults().map((assignment) => [assignment.key, assignment.item]).iterator();
	}
}

interface WritableResults {
	shared formal void write(Iterable<[Named,Named]> results);
}

class FileWriteableResults(Provider<Resource> resourceProvider) satisfies WritableResults {

	shared actual void write(Iterable<[Named,Named]> results) {
		value res = resourceProvider.get();
		switch (res)
		case (is Nil) {
			value file = res.createFile();
			try (overWriter = file.Overwriter()) {
				for (keyValue in results) {
					overWriter.writeLine(keyValue[0].name + ":" + keyValue[1].name);
				}
			}
		}
		else {
			throw Exception("Vysledky nesmu existovat!");
		}
	}

}


interface Named {
	shared formal String name;
}

interface Losovac satisfies Named {
	shared formal Integer choose(Integer optionsCount);
	shared formal void acquaintWithSelection(Named string);
}

interface Losovaci satisfies Iterable<Named>{


}

interface Klobuk {
	shared formal Integer getOptionsCount(Named named);
	shared formal Klobuk vylosovanie(Named losovac, Integer chosenOption);
	shared formal Named vylosovany(Named losovac);
}

class CliLosovac(shared actual String name) satisfies Losovac {

	shared actual void acquaintWithSelection(Named vylosovany) {
		print("Vybrana moznost: " + vylosovany.name);
		process.readLine();
		clearScreen();
	}

	shared actual Integer choose(Integer optionsCount) {
		value naturalNumber = NaturalNumberFromConsole(optionsCount);
		print("Losovac: ``name``");
		print("Moznosti: 1 .. ``optionsCount``");
		return naturalNumber.get();
	}
}

class FirstChoosingLosovac(shared actual String name) satisfies Losovac {

	shared actual void acquaintWithSelection(Named vylosovany) {
		print("Vybrana moznost: " + vylosovany.name);
	}

	shared actual Integer choose(Integer optionsCount) {
		print("Losovac: ``name``");
		print("Moznosti: 1 .. ``optionsCount``");
		return 1;
	}
}