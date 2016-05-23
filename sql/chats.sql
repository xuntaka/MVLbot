CREATE TABLE chats (
  id SERIAL PRIMARY KEY,
  ctime timestamp DEFAULT now(),
  chat_id int,
  type varchar(64) DEFAULT '',
  name varchar(64) DEFAULT '',
  link varchar(256) DEFAULT '',
  is_deleted boolean DEFAULT 'f',
  data jsonb
);
