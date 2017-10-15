#include <editors.hpp>
#include <code.hpp>
#include <iostream>

neko_editors::neko_editors(neko *machine) {
	this->states = new neko_editor_state *[EDITORS_SIZE];
	this->states[CODE_EDITOR] = new neko_code(machine);

	this->state = CODE_EDITOR;
}

neko_editors::~neko_editors() {
	for (int i = 0; i < EDITORS_SIZE; i++) {
		if (this->states[i] != nullptr) {
			delete this->states[i];
		}
	}

	delete [] this->states;
}

void neko_editors::escape(neko *machine) {
	this->states[this->state]->escape(machine);
}

void neko_editors::event(neko *machine, SDL_Event *event) {
	this->states[this->state]->event(machine, event);
}

void neko_editors::render(neko *machine) {
	this->states[this->state]->render(machine);
}