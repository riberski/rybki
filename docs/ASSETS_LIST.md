# Lista Wymaganych Assetów (Asset List)

## 1. Modele 3D

### Otoczenie (Environment)
- [ ] **Woda (Water Shader/Mesh)** - Bardziej zaawansowana powierzchnia wody (falowanie, piana).
- [ ] **Pomost (Dock)** - Model drewnianego pomostu (zamiast obecnego `BoxMesh`).
- [ ] **Sklep (Shop Building)** - Model chatki rybackiej / straganu na pomoście.
- [ ] **Skały / Przeszkody (Rocks)** - Zestaw kilku wariantów skał wystających z wody (do kolizji).
- [ ] **Roślinność (Vegetation)** - Trzciny, lilie wodne (opcjonalne, dla klimatu).

### Gracz i Sprzęt (Player & Gear)
- [ ] **Postać Gracza (Fisherman)** - Model postaci (zamiast `CapsuleMesh`), ewentualnie z animacjami rzutu/zwijania.
- [ ] **Łódź (Boat)** - Model łodzi rybackiej (zamiast `BoxMesh`). Musi pasować do fizyki/hitboxa.
- [ ] **Wędka (Fishing Rod)** - Model wędki z kołowrotkiem (zamiast `CylinderMesh`).
- [ ] **Spławik (Bobber)** - Model spławika (czerwono-biały klasyk lub inny).

### Ryby (Fish Models)
*Jeśli planujemy pokazywać rybę w 3D po złowieniu lub w wodzie:*
- [ ] **Karp (Carp)**
- [ ] **Okoń (Bass)**
- [ ] **Złoty Pstrąg (Golden Trout)**
- [ ] **Sum (Catfish)**
- [ ] **Szczupak (Pike)**
- [ ] **Węgorz Elektryczny (Electric Eel)**
- [ ] **Sum Gigant (Giant Catfish)**

---

## 2. Grafika 2D (UI & Textures)

### Ikony (Icons)
- **Ryby (Fish Icons):**
    - [ ] Karp, Okoń, Złoty Pstrąg, Sum, Szczupak, Węgorz, Sum Gigant.
- **Przynęty (Bait Icons):**
    - [ ] Chleb (Bread)
    - [ ] Robak (Worm)
    - [ ] Krewetka (Shrimp)
- **Relikty (Relic Icons) - Do Draft UI:**
    - [ ] Reinforced Hull (Naprawa / Klucz)
    - [ ] Steel Plating (Płyta metalowa / Tarcza)
    - [ ] Impact Absorber (Poduszka / Sprężyna)
    - [ ] Lucky Charm (Koniczynka / Podkowa)
    - [ ] Turbo Reel (Kołowrotek z błyskawicą)
    - [ ] Titanium Line (Gruba żyłka / Łańcuch)
    - [ ] Fish Marketing (Znak dolara / Wykres)
    - [ ] Scented Lure (Buteleczka zapachowa)
    - [ ] Cursed Hook (Hak z fioletową poświatą / Czaszką)
    - [ ] Glass Cannon (Pęknięta tarcza / Działo)
- **Ogólne (General UI):**
    - [ ] Waluta (Moneta / Łuska)
    - [ ] Wytrzymałość Kadłuba (Serce / Łódź)
    - [ ] Ikona Dnia / Zzegara.

### Tekstury (Textures)
- [ ] **Drewno (Wood Planks)** - Na pomost i łódź.
- [ ] **Kamień (Rock)** - Na przeszkody.
- [ ] **Skybox** - Pora dnia (słonecznie) i Noc (gwiazdy/księżyc).
- [ ] **Cząsteczki (Particles)** - Kropla deszczu, Rozbryzg wody (Splash sprite).

---

## 3. Audio (Sound Effects & Music)

### Efekty Dźwiękowe (SFX)
- [ ] **Rzut (Cast)** - Świst wędki (`Whoosh`).
- [ ] **Plusk (Splash)** - Uderzenie spławika o wodę.
- [ ] **Branie (Bite)** - Dźwięk alarmu / dzwoneczka / plusku.
- [ ] **Zwijanie (Reeling)** - Dźwięk kołowrotka (cykanie/szum).
- [ ] **Napięcie (Tension)** - Dźwięk naprężanej żyłki (skrzypienie).
- [ ] **Zerwanie (Snap)** - Dźwięk pękającej żyłki.
- [ ] **Sukces (Catch)** - Pozytywny dźwięk / jingle przy złowieniu.
- [ ] **Silnik / Wiosła** - Dźwięk poruszania się łodzią.
- [ ] **Uderzenie (Collision)** - Drewniany trzask przy uderzeniu w skałę.
- [ ] **UI** - Kliknięcie przycisku, najechanie myszką, zakup w sklepie (dźwięk monety).

### Ambience & Muzyka
- [ ] **Ambience Dzień** - Szum wody, śpiew ptaków.
- [ ] **Ambience Noc** - Świerszcze, pohukiwanie sowy, wiatr.
- [ ] **Pogoda** - Szum deszczu, grzmoty (opcjonalnie).
- [ ] **Muzyka (BGM)** - Spokojna pętla (chill lo-fi fishing beat?).
- [ ] **Muzyka Sklep** - Osobny motyw dla sklepu (opcjonalnie).

---

## 4. VFX (Visual Effects)
- [ ] **Rozbryzg Wody (Water Splash)** - Particle system przy rzucie i walce z rybą.
- [ ] **Deszcz (Rain)** - Shader lub Particle system (już zaimplementowane, można ulepszyć grafikę).
- [ ] **Mgła (Fog)** - Shader (już zaimplementowane, można ulepszyć).
- [ ] **Szuranie po dnie / Kilwater** - Ślad na wodzie za łodzią.
