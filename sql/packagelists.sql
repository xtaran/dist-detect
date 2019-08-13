-- 1 up

CREATE TABLE packagelists (
  filename TEXT PRIMARY KEY,
  url TEXT NOT NULL,
  fetched DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 1 down

DROP TABLE IF EXISTS packagelists;
