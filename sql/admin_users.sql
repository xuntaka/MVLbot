CREATE TABLE admin_users (
  id SERIAL PRIMARY KEY,
  ctime timestamp DEFAULT now(),
  login varchar(64) UNIQUE,
  name varchar(64) DEFAULT '',
  email varchar(64) UNIQUE,
  password varchar(32) DEFAULT '',
  password_salt varchar(8) DEFAULT '',
  is_deleted boolean DEFAULT 'f',
  data jsonb
);
