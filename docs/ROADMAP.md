# Fishing Rogue - Roadmap Tygodniowa do Release 1.0 (Wrzesien 2026)

Plan prowadzi projekt do wydania na Steam (PC) pod koniec wrzesnia 2026.

## Cel 1.0

- Platforma: PC (Steam)
- Zakres: Co-op 2-4 graczy + solo
- Priorytet: stabilny pelny run od lobby do ekstrakcji i zapisu postepu

## Tygodniowe Taski (W1-W26)

## Kwiecien

### W1
- Scope lock 1.0 (dzien 1)
	- Potwierdzic, co jest w 1.0: solo + co-op 2-4, pelny run lobby -> run -> extraction -> save
	- Przeniesc wszystkie nowe pomysly poza 1.0 do backlogu post-launch
	- Zamknac dokument "IN/OUT 1.0" i podlaczyc go do ROADMAP
- Definition of Done dla pelnego runu (dzien 2)
	- Spisac warunki "run uznany za dzialajacy" dla solo i co-op
	- Spisac edge-case: rozlaczenie hosta, smierc gracza, fail extraction, game over
	- Dodac checkliste akceptacyjna dla kazdego przypadku konca runu
- Checklisty regresji E2E (dzien 3)
	- Przygotowac 2 scenariusze solo i 3 scenariusze co-op
	- Zdefiniowac kroki testu: start sesji, lowienie, quota/day, extraction, save/load
	- Dodac expected result do kazdego kroku (pass/fail)
- Porzadek techniczny pod kolejne tygodnie (dzien 4)
	- Przejrzec flow sygnalow miedzy UI, quota, inventory, fishing
	- Oznaczyc miejsca wymagajace refaktoru przed multiplayerem
	- Spisac liste bugow blokujacych W2-W4
- Zamkniecie tygodnia W1 (dzien 5)
	- Przejsc wszystkie checklisty E2E i zapisac wynik
	- Ustalic priorytet top 10 bugow na W2
	- Zrobic demo build i decyzje go/no-go na rozpoczecie W2

### W2
- Domknac przeplyw lobby -> start runu -> powrot do lobby
- Ujednolicic save/load po udanym i nieudanym runie
- Naprawic najwazniejsze bugi blokujace start sesji

### W3
- Posprzatac flow 3D i sygnaly miedzy glownymi systemami
- Odczac pozostalosci legacy 2D od glownego runtime
- Ustabilizowac przejscia scen i respawn playera

### W4
- Wlaczyc host-authoritative podstawy dla ruchu gracza i lodzi
- Podpiac synchronizacje start/koniec runu dla klientow
- Dodac podstawowe logowanie bledow sieciowych

## Maj

### W5
- Rozszerzyc authority o kluczowe stany gameplayu podczas runu
- Dodac klientowa korekte pozycji i wygladzenie ruchu
- Naprawic przypadki rozjazdu pozycji po lagach

### W6
- Zsynchronizowac cast/hook/reel miedzy hostem i klientami
- Ujednolicic rozstrzyganie wyniku lowienia po stronie hosta
- Usunac podwojne nagrody i rozjazdy inventory

### W7
- Ustabilizowac spawn ryb i wynik kolizji w co-op
- Dodac recovery po utracie polaczenia gracza
- Dopiac bezpieczne zamkniecie runu przy bledzie sieci

### W8
- Podpiac lobby Steam: create, join, leave
- Dopic invite flow i status gotowosci graczy
- Dodac komunikaty bledow polaczenia w UI

### W9
- Zrobic pelny tydzien testow soak dla 2p i 4p
- Zredukowac krytyczne bugi sieciowe do stabilnego poziomu
- Zamknac zalegle poprawki multiplayer przed faza polish

## Czerwiec

### W10
- Zbalansowac podstawowe krzywe trudnosci minigry lowienia
- Uporzadkowac timing windows dla fish tierow
- Dopracowac feedback gracza przy hook/catch/loss

### W11
- Zbalansowac ekonomie quota i tempo progresji dnia
- Poprawic relacje: wartosc ryb, koszt przynet, ryzyko runu
- Ograniczyc snowball po kilku dobrych runach

### W12
- Dopracowac wplyw pogody na lowienie i nawigacje
- Uczytelnic hazardy sektorow i ich sygnalizacje
- Ujednolicic trudnosc miedzy sektorami startowymi i trudnymi

### W13
- Zamknac finalna liste ryb i sektorow do 1.0
- Zamknac finalna liste kontraktow do 1.0
- Przeniesc wszystkie nowe pomysly do backlogu post-launch

### W14
- Zrobic playtesty zewnetrzne i zebrac feedback
- Poprawic UX edge-case wykryte podczas testow
- Dopic brakujace drobne elementy contentowe

## Lipiec

### W15
- Poprawic onboarding pierwszych minut gry
- Dodac czytelny ready-check i stany graczy w co-op
- Ujednolicic krytyczne komunikaty UI w trakcie runu

### W16
- Uporzadkowac UX lobby i przeplyw New Game/Continue/Co-op
- Uczytelnic panel przygotowania do runu
- Skrocic liczbe krokow do rozpoczecia wyprawy

### W17
- Zrobic glowny pass wydajnosci CPU/GPU w scenach runtime
- Ograniczyc najciezsze efekty i poprawic culling/LOD
- Dopracowac presety quality pod slabse PC

### W18
- Zrobic pass stabilnosci dla dlugich sesji
- Usunac glowniejsze hiche i wycieki pamieci
- Domknac bugi blokujace przejscie do QA lock

## Sierpien

### W19
- Wlaczyc feature freeze i content lock
- Przejsc na tryb bugfix + polish
- Ustalic codzienny proces triage i priorytetyzacji

### W20
- Redukowac bugi S1/S2 z naciskiem na co-op i save/load
- Ustabilizowac krytyczne sciezki lobby -> run -> extraction
- Utrzymac codzienne buildy testowe

### W21
- Przeprowadzic closed beta i zbierac raporty
- Naprawic najczestsze problemy z feedbacku graczy
- Dopracowac onboarding i readability UI po becie

### W22
- Domknac przygotowanie wydania na Steam
- Zaktualizowac store page i finalne materialy
- Zamknac release checklist i pipeline buildow

## Wrzesien

### W23
- Przygotowac i wypuscic RC1
- Naprawic blockery znalezione po RC1
- Potwierdzic stabilnosc pelnego runu E2E

### W24
- Przygotowac i wypuscic RC2
- Zamknac regresje krytyczne i problemy multiplayer
- Zrobic finalny przeglad go/no-go

### W25
- Wypuscic build release 1.0
- Uruchomic monitoring po premierze i tryb on-call
- Triage bugow z pierwszych dni po starcie

### W26
- Wypuscic hotfix 1 dla problemow krytycznych
- Wypuscic hotfix 2 dla wysokiego impactu UX/perf
- Przygotowac plan patcha 1.1 na podstawie feedbacku

## Rytm Pracy Tygodnia

- Poniedzialek: plan sprintu i podzial zadan
- Sroda: przeglad postepu i korekta zakresu
- Piatek: demo build, decyzje na kolejny tydzien

## Co Nie Wchodzi do 1.0

- Prestiz i reset progresji
- Duze wydarzenia sezonowe
- Rozszerzone social/leaderboards
- Dodatkowe sektory premium
