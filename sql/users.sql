CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  ctime timestamp DEFAULT now(),
  email varchar(64) UNIQUE,
  name varchar(64) DEFAULT '',
  password varchar(32) DEFAULT '',
  password_salt varchar(8) DEFAULT '',
  money decimal(16,4),
  is_deleted boolean DEFAULT 'f',
  data jsonb
);
