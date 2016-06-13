CREATE TABLE houses (
  id SERIAL PRIMARY KEY,
  pid integer DEFAULT 0,
  ctime timestamp DEFAULT now(),
  type varchar(64),
  title varchar(64),
  is_deleted boolean DEFAULT 'f',
  data jsonb
);
