CREATE TABLE lists (
	PRIMARY KEY(id),
	id serial, 
	name text NOT NULL UNIQUE
);

CREATE TABLE todo (
	PRIMARY KEY(id),
	id serial, 
	name text NOT NULL, 
	completed boolean NOT NULL DEFAULT false,
	list_id integer NOT NULL REFERENCES lists(id) ON DELETE CASCADE
);
