--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

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

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: guests; Type: TABLE; Schema: public; Owner: xenscan; Tablespace: 
--

CREATE TABLE guests (
    id integer DEFAULT nextval('guests_id_seq'::regclass) NOT NULL,
    guestname character varying(256),
    host_id integer
);


ALTER TABLE public.guests OWNER TO xenscan;

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
    id integer DEFAULT nextval('hosts_id_seq'::regclass) NOT NULL,
    hostname character varying(256),
    osname character varying(256),
    rebooted boolean DEFAULT false,
    datacenter character varying(64)
);


ALTER TABLE public.hosts OWNER TO xenscan;

--
-- Name: installs; Type: TABLE; Schema: public; Owner: xenscan; Tablespace: 
--

CREATE TABLE installs (
    id integer NOT NULL,
    host_id integer,
    package_id integer
);


ALTER TABLE public.installs OWNER TO xenscan;

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
-- Name: installs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xenscan
--

ALTER SEQUENCE installs_id_seq OWNED BY installs.id;


--
-- Name: packages; Type: TABLE; Schema: public; Owner: xenscan; Tablespace: 
--

CREATE TABLE packages (
    id integer NOT NULL,
    name character varying(64) NOT NULL,
    version character varying(64) NOT NULL,
    release character varying(64) NOT NULL,
    arch character varying(64) NOT NULL
);


ALTER TABLE public.packages OWNER TO xenscan;

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
-- Name: packages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xenscan
--

ALTER SEQUENCE packages_id_seq OWNED BY packages.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: xenscan
--

ALTER TABLE ONLY installs ALTER COLUMN id SET DEFAULT nextval('installs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: xenscan
--

ALTER TABLE ONLY packages ALTER COLUMN id SET DEFAULT nextval('packages_id_seq'::regclass);


--
-- Name: guests_guestname_key; Type: CONSTRAINT; Schema: public; Owner: xenscan; Tablespace: 
--

ALTER TABLE ONLY guests
    ADD CONSTRAINT guests_guestname_key UNIQUE (guestname);

ALTER TABLE guests CLUSTER ON guests_guestname_key;


--
-- Name: guests_pkey; Type: CONSTRAINT; Schema: public; Owner: xenscan; Tablespace: 
--

ALTER TABLE ONLY guests
    ADD CONSTRAINT guests_pkey PRIMARY KEY (id);


--
-- Name: hosts_hostname_key; Type: CONSTRAINT; Schema: public; Owner: xenscan; Tablespace: 
--

ALTER TABLE ONLY hosts
    ADD CONSTRAINT hosts_hostname_key UNIQUE (hostname);

ALTER TABLE hosts CLUSTER ON hosts_hostname_key;


--
-- Name: hosts_pkey; Type: CONSTRAINT; Schema: public; Owner: xenscan; Tablespace: 
--

ALTER TABLE ONLY hosts
    ADD CONSTRAINT hosts_pkey PRIMARY KEY (id);


--
-- Name: packages_pkey; Type: CONSTRAINT; Schema: public; Owner: xenscan; Tablespace: 
--

ALTER TABLE ONLY packages
    ADD CONSTRAINT packages_pkey PRIMARY KEY (id);


--
-- Name: guests_host_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xenscan
--

ALTER TABLE ONLY guests
    ADD CONSTRAINT guests_host_id_fkey FOREIGN KEY (host_id) REFERENCES hosts(id);


--
-- Name: installs_host_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xenscan
--

ALTER TABLE ONLY installs
    ADD CONSTRAINT installs_host_id_fkey FOREIGN KEY (host_id) REFERENCES hosts(id);


--
-- Name: installs_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xenscan
--

ALTER TABLE ONLY installs
    ADD CONSTRAINT installs_package_id_fkey FOREIGN KEY (package_id) REFERENCES packages(id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

