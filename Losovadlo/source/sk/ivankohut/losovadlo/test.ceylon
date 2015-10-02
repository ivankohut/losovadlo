import ceylon.collection {
	HashMap,
	HashSet
}
import ceylon.test {
	test,
	assertNull,
	assertEquals
}

object leastAflabeticalChooser satisfies LosovacChooser {
	shared actual Losovac choose({Losovac*} losovaci) {
		value zotriedeni = losovaci.sort((Losovac x, Losovac y) => x.name.compare(y.name));
		assert (exists prvyLosovac = zotriedeni.first);
		return prvyLosovac;
	}
}

Losovadlo create([Losovac, Losovac+] losovaci) {
	return Losovadlo(losovaci, leastAflabeticalChooser);
}

test shared void noOptionsWhenJustTwoLosovaci() {
	value sut = create([Losovac("Miso"), Losovac("Fero")]);
	// run & verify
	assertNull(sut.getOptions());
}

test shared void firstToSecondAndSecondToFirstWhenJustTwoLosovaci() {
	value miso = Losovac("Miso");
	value fero = Losovac("Fero");
	value sut = create([miso, fero]);
	// run
	value result = sut.getResults();
	// verify
	assertEquals(result, HashMap{entries = {miso -> fero, fero -> miso};});
}

test shared void twoOptionsForFirstLosovacWhenJustThreeLosovaci() {
	value miso = Losovac("Miso");
	value fero = Losovac("Fero");
	value jano = Losovac("Jano");
	value sut = create([miso, fero, jano]);
	// run 
	assert (exists options = sut.getOptions());
	// verify
	assertEquals(options[0], fero);
	assertEquals(HashSet{elements = options[1];}, HashSet{elements = [miso, jano];});
}

test shared void noOptionsAfterFirstWhenJustThreeLosovaci() {
	value miso = Losovac("Miso");
	value fero = Losovac("Fero");
	value jano = Losovac("Jano");
	value sut = create([miso, fero, jano]);
	// run 
	sut.setSelection(jano);
	// verify
	assertNull(sut.getOptions());
	assertEquals(sut.getResults().get(fero), jano);
	assertEquals(sut.getResults().get(miso), fero);
	assertEquals(sut.getResults().get(jano), miso);
}

test shared void twoOptionsWhenLastTwoChooseFromAnotherTwo() {
	value duro = Losovac("Duro");
	value fero = Losovac("Fero");
	value jano = Losovac("Jano");
	value miso = Losovac("Miso");
	value sut = create([miso, fero, jano, duro]);
	// run
	sut.setSelection(jano);
	sut.setSelection(miso);
	assert (exists options = sut.getOptions());
	// verify
	assertEquals(options[0], jano);
	assertEquals(HashSet{elements = options[1];}, HashSet{elements = [duro, fero];});
	
	assertEquals(sut.getResults(), HashMap{entries = {
		duro -> jano, 
		fero -> miso
	};});
}

test shared void noOptionsWhenLastTwoChooseFromOneOfThemAndAnother() {
	value duro = Losovac("Duro");
	value fero = Losovac("Fero");
	value jano = Losovac("Jano");
	value miso = Losovac("Miso");
	value sut = create([miso, fero, jano, duro]);
	// run
	sut.setSelection(jano);
	sut.setSelection(duro);
	// verify
	assertNull(sut.getOptions());

	assertEquals(sut.getResults(), HashMap{entries = {
		duro -> jano, 
		fero -> duro,
		jano -> miso,
		miso -> fero
	};});
}

test shared void noOptionsWhenLastTwoChooseFromThemselves() {
	value duro = Losovac("Duro");
	value fero = Losovac("Fero");
	value jano = Losovac("Jano");
	value miso = Losovac("Miso");
	value sut = create([miso, fero, jano, duro]);
	// run
	sut.setSelection(fero);
	sut.setSelection(duro);
	// verify
	assertNull(sut.getOptions());

	assertEquals(sut.getResults(), HashMap{entries = {
		duro -> fero, 
		fero -> duro,
		jano -> miso,
		miso -> jano
	};});
}

