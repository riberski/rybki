# GDD - Rybki (3D Solo MVP)

Status: aktywny draft produkcyjny
Data: 2026-04-01
Silnik: Godot 4.x
Tryb: singleplayer

## 1. Wizja Gry
Rybki to 3D gra o lowieniu ryb w krotkich, napietych wyprawach. Kazdy run to decyzje o ryzyku, czasie i zasobach. Gracz wraca do bazy, sprzedaje lup, inwestuje zarobek i przygotowuje kolejna wyprawe.

Cel projektu na tym etapie:
- domknac stabilny, czytelny i powtarzalny core loop,
- zbudowac ekonomie, ktora nagradza dobre decyzje, a nie grind,
- usunac systemy, ktore nie wspieraja bezposrednio petli runu.

## 2. Filary Projektowe
1. Krotkie runy z jasnym celem: low i wroc przed koncem czasu.
2. Czytelna decyzja ryzyko vs nagroda: zostac dluzej czy wracac teraz.
3. Znaczace zarzadzanie zasobami: przyneta, miejsce, czas.
4. Prosta, ale satysfakcjonujaca progresja miedzy wyprawami.
5. Zero ukrytych systemow dzialajacych "same z siebie" poza runem.

## 3. Zakres MVP

### 3.1 W zakresie
- lowienie: cast -> bite -> hook -> hol/minigra,
- timer wyprawy (extraction timer),
- ekonomia przynet,
- inventory i sprzedaz ryb,
- loadout lodzi,
- podstawowe ulepszenia,
- proste kontrakty/questy,
- UI: baza, sklep, inventory, HUD wyprawy, pause.

### 3.2 Poza zakresem
- globalny czas dnia/nocy dzialajacy stale w tle,
- HP lodzi (Hull), obrazenia i game over od zniszczenia,
- system skills i drzewko skilli,
- pelny coop/multiplayer,
- duzy codex i systemy meta niezbedne dopiero po MVP.

## 4. Potwierdzone Decyzje
1. Kierunek techniczny: 3D.
2. Priorytet: Solo MVP.
3. Globalny czas w tle: usuniety.
4. Jedyny czas krytyczny: timer wyprawy.
5. Hull/HP lodzi: usuniete z gameplayu MVP.
6. Skills: usuniete z gameplayu MVP.

## 5. Core Loop
1. Baza
- Gracz sprawdza budzet, stan przynet i miejsce w ladunku.
- Kupuje przynety i przygotowuje loadout.

2. Start wyprawy
- Uruchamia sie timer wyprawy.
- Gracz wyplywa do lowiska i zaczyna lowienie.

3. Lowienie
- Rzut przynety i oczekiwanie na branie.
- Po braniu gracz wykonuje podciecie i rozgrywa minigre holowania.
- Sukces: ryba trafia do puli wyprawy.
- Porazka: ryba ucieka, a zasob/czas zostaje zuzyty.

4. Decyzja o zakonczeniu
- Powrot automatyczny po timeout.
- Powrot reczny (early return), jesli warunek jest aktywny.
- Optional balansowy: automatyczny koniec po braku przynet.

5. Rozliczenie
- Ryby sa rozliczane zgodnie z zasadami inventory.
- Gracz sprzedaje lup i otrzymuje gotowke.
- Aktualizuje sie postep kontraktow.

6. Metagra
- Gracz inwestuje zarobek i planuje kolejny run.

## 6. Warunki Porazki
W MVP nie ma klasycznego fail-state opartego o HP lodzi.

Porazka ma forme ekonomiczna:
- slaby run daje zbyt maly zwrot,
- zle decyzje ograniczaja mozliwosci kolejnej wyprawy,
- optional: kara ekonomiczna, jesli wyprawa nie pokrywa kosztu wejscia.

Nie ma globalnego ekranu game over wynikajacego z uszkodzen lodzi.

## 7. Ekonomia MVP
Petla wartosci:
lowienie -> wartosc ryb -> sprzedaz -> budzet -> zakupy/ulepszenia -> kolejna wyprawa

Zasady balansu:
- przyneta jest glownym limiterem tempa,
- timer wymusza priorytety i planowanie,
- nagrody maja premiowac skutecznosc, nie dlugosc sesji,
- progresja nie moze opierac sie na ukrytym "free power".

## 8. UX i Readability
HUD i UI musza zawsze jasno komunikowac:
- czas pozostaly do konca wyprawy,
- stan przynet,
- wartosc obecnego lupu,
- konsekwencje natychmiastowego powrotu.

Cel UX: gracz ma przegrywac przez decyzje, nie przez brak informacji.

## 9. Kryteria Akceptacji MVP
1. Brak stalego systemu czasu dnia/nocy produkujacego zasoby poza runem.
2. Kazdy run opiera sie na jednym timerze wyprawy.
3. Brak zaleznosci gameplayu od Hull/HP lodzi.
4. Brak aktywnego systemu Skills w logice i UI.
5. Core loop dziala end-to-end przez minimum 3 kolejne wyprawy bez blokera.
6. Rozliczenie economy po runie jest deterministyczne i czytelne dla gracza.

## 10. Ryzyka
- Progresja moze byc zbyt plaska po usunieciu Hull i Skills.
- Bez globalnego czasu pacing economy wymaga precyzyjnego balansu.
- W kodzie i UI moga pozostac osierocone sygnaly po usunietych systemach.

## 11. Milestone Po MVP (orientacyjnie)
1. Dopiero po stabilnym MVP: co-op 2-4, etapami.
2. Rozszerzenie contentu (ryby, sektory, kontrakty).
3. Powrot do meta-systemow tylko jesli poprawia core loop.

## 12. Najblizsze Kroki Implementacyjne
1. Refactor TimeManager do modelu extraction-only.
2. Usuniecie pozostalych referencji Hull i Skills z UI oraz systemow runtime.
3. Testy scenariuszy: timeout, early return, brak przynet, rozliczenie runu.
4. Korekta economy po testach 3-run sequence.
