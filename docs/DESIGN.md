# Fishing Roguelite - Game Design Document

**Tytuł roboczy:** Fishingrogue Multiplayer
**Silnik:** Godot 4.5
**Gatunek:** 2D Multiplayer Roguelite / Fishing Sim
**Tryby:** Co-op (2-4 graczy) lub Competitive (Rywalizacja).

---

## 1. Idea Gry (High Concept)
Wieloosobowa gra, w której drużyna rybaków musi współpracować (lub rywalizować), aby złowić legendarne stworzenia w niebezpiecznych wodach. Każda wyprawa to ryzyko - jeśli wszyscy zginą, łódź tonie wraz z łupem.

## 2. Pętla Rozgrywki (Core Loop)
1.  **Lobby/Baza:** Gracze wybierają sprzęt i role (np. Sternik, Rybak, Kucharz).
2.  **Wyprawa (Multiplayer):**
    -   Hostowanie sesji, dołączanie via IP/Steam.
    -   Wspólna łódź lub oddzielne stanowiska na brzegu.
3.  **Łowienie (Mechanika):**
    -   Każdy gracz zarzuca własną wędkę.
    -   Minigra jest lokalna dla klienta, ale wynik (sukces/porażka) jest synchronizowany.
    -   Możliwość pomagania sobie (np. podbierak, nęcenie).
4.  **Zarządzanie Zasobami:**
    -   Wspólny "Bagażnik" (Inventory) na łodzi.
    -   Jedzenie ryb regeneruje zdrowie drużyny.
5.  **Koniec Runu:**
    -   Sukces: Powrót do bazy z łupem.
    -   Porażka: Śmierć wszystkich graczy = Game Over.

## 3. Multiplayer Architecture (Godot High-Level Multiplayer)
-   **Host-Server Authority:** Host zarządza stanem świata, rybami i pogodą.
-   **Client Prediction:** Gracze kontrolują swoje postacie lokalnie, pozycja jest synchronizowana.
-   **Synchronizacja:**
    -   Pozycja graczy (`MultiplayerSynchronizer`).
    -   Stan wędki (Idle/Casting/Reeling).
    -   Obiekty fizyczne (spławiki) spawnowane przez `MultiplayerSpawner`.

## 4. Mechaniki Szczegółowe (Zaktualizowane)


### 3.1. System Łowienia (Fishing System)
-   **Wędka:** Główna broń gracza. Może mieć statystyki: Wytrzymałość, Zasięg, Moc przyciągania.
-   **Szansa na branie:** Zależy od: przynęty, pory dnia, biomu.
-   **Minigra Walki:** Pasek postępu, gdzie kursor ryby porusza się losowo/wzorem, a gracz musi utrzymać swój pasek na rybie (jak w Stardew Valley, ale bardziej dynamicznie).

### 3.2. Roguelite Elements
-   **Biomy:** Proceduralnie generowane (np. Spokojne Jezioro -> Bagna -> Sztormowe Wybrzeże).
-   **Karty/Ulepszenia:** Po pokonaniu bossa lub znalezieniu skrzyni, wybierasz 1 z 3 ulepszeń (np. "Żyłka ze stali" - większa wytrzymałość, "Nocny Marek" - lepsze brania w nocy).

## 4. Styl Artystyczny (Art Direction)
-   **Kreska:** "Bazgroły" długopisem, pociągnięcia ołówka, akwarele.
-   **Kolorystyka:** Stonowana, z jaskrawymi akcentami dla ryb rzadkich/niebezpiecznych.
-   **UI:** Wyglądające jak notatnik rybaka (papierowe tło, odręczne pismo).

## 5. Architektura Techniczna (Godot)
-   **Gracz (`Player.gd`):** `CharacterBody2D` - ruch, stan (idle, casting, reeling).
-   **Wędka (`Rod.gd`):** `Node2D` - wizualizacja żyłki (`Line2D`), punkt zaczepienia.
-   **Spławik/Haczyk (`Bobber.gd`):** `RigidBody2D` - fizyka rzutu, detekcja wody.
-   **Ryba (`Fish.gd`):** `Area2D` / `CharacterBody2D` - AI (ucieczka, walka).
-   **Woda (`WaterBody.gd`):** `Area2D` z shaderem powierzchni i fizyką wyporności.
