--
-- PostgreSQL database dump
--

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: hosts_id_seq; Type: SEQUENCE; Schema: public; Owner: xenscan
--

CREATE SEQUENCE hosts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.hosts_id_seq OWNER TO xenscan;

--
-- Name: hosts; Type: TABLE; Schema: public; Owner: xenscan; Tablespace: 
--

CREATE TABLE hosts (
    id integer DEFAULT nextval('hosts_id_seq'::regclass) NOT NULL PRIMARY KEY,
    hostname character varying(256) UNIQUE,
    osname character varying(256)
);


ALTER TABLE public.hosts OWNER TO xenscan;

--
-- Name: guests_id_seq; Type: SEQUENCE; Schema: public; Owner: xenscan
--

CREATE SEQUENCE guests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.guests_id_seq OWNER TO xenscan;

--
-- Name: guests; Type: TABLE; Schema: public; Owner: xenscan; Tablespace: 
--

CREATE TABLE guests (
    id integer DEFAULT nextval('guests_id_seq'::regclass) NOT NULL PRIMARY KEY,
    guestname character varying(256) UNIQUE,
    host_id integer,
    FOREIGN KEY (host_id) REFERENCES hosts (id)
);


ALTER TABLE public.guests OWNER TO xenscan;

--
-- Name: packages_id_seq; Type: SEQUENCE; Schema: public; Owner: xenscan
--

CREATE SEQUENCE packages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.packages_id_seq OWNER TO xenscan;

--
-- Name: packages; Type: TABLE; Schema: public; Owner: xenscan; Tablespace: 
--

CREATE TABLE packages (
    id integer DEFAULT nextval('packages_id_seq'::regclass) NOT NULL PRIMARY KEY,
    name character varying(64) NOT NULL,
    version character varying(64) NOT NULL,
    release character varying(64) NOT NULL,
    arch character varying(64) NOT NULL
);


ALTER TABLE public.packages OWNER TO xenscan;

--
-- Name: packages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xenscan
--

ALTER SEQUENCE packages_id_seq OWNED BY packages.id;


--
-- Name: installs_id_seq; Type: SEQUENCE; Schema: public; Owner: xenscan
--

CREATE SEQUENCE installs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.installs_id_seq OWNER TO xenscan;

--
-- Name: installs; Type: TABLE; Schema: public; Owner: xenscan; Tablespace: 
--

CREATE TABLE installs (
    id integer DEFAULT nextval('installs_id_seq'::regclass) NOT NULL,
    host_id integer,
    package_id integer,
    FOREIGN KEY (host_id) REFERENCES hosts (id),
    FOREIGN KEY (package_id) REFERENCES packages (id)
);


ALTER TABLE public.installs OWNER TO xenscan;

--
-- Name: installs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xenscan
--

ALTER SEQUENCE installs_id_seq OWNED BY installs.id;


--
-- PostgreSQL database dump complete
--

