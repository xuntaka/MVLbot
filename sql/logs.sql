CREATE TABLE logs (
  id SERIAL PRIMARY KEY,
  ctime timestamp DEFAULT now(),
  object_class varchar(255),
  object_id int,
  user_class varchar(255),
  user_id int,
  action varchar(255),
  comment text,
  data jsonb
);
