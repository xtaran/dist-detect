-- 1 up

CREATE TABLE version2os (
  id INTEGER PRIMARY KEY,
  version TEXT NOT NULL,
  os TEXT NOT NULL,
  tags TEXT NOT NULL DEFAULT "",
  source TEXT NOT NULL DEFAULT "manual",
  created DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  lastmod DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE banner2version (
  banner TEXT,
  regexp BOOLEAN NOT NULL DEFAULT FALSE,
  version TEXT,
  source TEXT NOT NULL DEFAULT "manual",
  created DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  lastmod DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  os TEXT,
  PRIMARY KEY (banner, os, version)
);


CREATE TABLE osreleases (
  short TEXT,
  os TEXT,
  long BOOLEAN NOT NULL DEFAULT FALSE,
  version TEXT,
  source TEXT NOT NULL DEFAULT "manual",
  created DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  lastmod DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (short, os, version)
);

-- 1 down

DROP TABLE IF EXISTS ssh2os;
DROP TABLE IF EXISTS banner2version;
