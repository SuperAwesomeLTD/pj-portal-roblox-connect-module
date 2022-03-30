ROJO = rojo

SHARED = shared

LOBBY_PLACE = Lobby.rbxlx
LOBBY_SRC = Lobby/src
LOBBY_PROJECT = Lobby/default.project.json

ALTERNATE_PLACE = Alternate.rbxlx
ALTERNATE_SRC = Alternate/src
ALTERNATE_PROJECT = Alternate/default.project.json

MINIGAME_PLACE = Minigame.rbxlx
MINIGAME_SRC = Minigame/src
MINIGAME_PROJECT = Minigame/default.project.json

ALL_PLACES = $(LOBBY_PLACE) $(ALTERNATE_PLACE) $(MINIGAME_PLACE)

find_files = $(shell find $(dir) -type f)

.PHONY : all lobby alternate minigame

all : $(ALL_PLACES)

lobby : $(LOBBY_PLACE)

$(LOBBY_PLACE) : $(LOBBY_PROJECT)  $(shell find $(LOBBY_SRC) -type f) $(shell find $(SHARED) -type f)
	$(ROJO) build --output "$(LOBBY_PLACE)" "$(LOBBY_PROJECT)"

alternate : $(ALTERNATE_PLACE)

$(ALTERNATE_PLACE) : $(ALTERNATE_PROJECT)  $(shell find $(ALTERNATE_SRC) -type f) $(shell find $(SHARED) -type f)
	$(ROJO) build --output "$(ALTERNATE_PLACE)" "$(ALTERNATE_PROJECT)"

minigame : $(MINIGAME_PLACE)

$(MINIGAME_PLACE) : $(MINIGAME_PROJECT)  $(shell find $(MINIGAME_SRC) -type f) $(shell find $(SHARED) -type f)
	$(ROJO) build --output "$(MINIGAME_PLACE)" "$(MINIGAME_PROJECT)"

clean :
	$(RM) $(ALL_PLACES)
