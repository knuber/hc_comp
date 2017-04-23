--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.2
-- Dumped by pg_dump version 9.6.2

-- Started on 2017-04-21 17:18:32

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 12 (class 2615 OID 16386)
-- Name: fc; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA fc;


--
-- TOC entry 12753 (class 0 OID 0)
-- Dependencies: 12
-- Name: SCHEMA fc; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA fc IS 'Forecasting environment';


SET search_path = fc, pg_catalog;

SET default_with_oids = false;

--
-- TOC entry 288 (class 1259 OID 16936)
-- Name: agnt; Type: TABLE; Schema: fc; Owner: -
--

CREATE TABLE agnt (
    agent text,
    fbasis text
);


--
-- TOC entry 12754 (class 0 OID 0)
-- Dependencies: 288
-- Name: TABLE agnt; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON TABLE agnt IS 'forecasting agents & time basis';


--
-- TOC entry 289 (class 1259 OID 16942)
-- Name: agntf; Type: TABLE; Schema: fc; Owner: -
--

CREATE TABLE agntf (
    agent text,
    fbasis text,
    val numeric
);


--
-- TOC entry 12755 (class 0 OID 0)
-- Dependencies: 289
-- Name: TABLE agntf; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON TABLE agntf IS 'agent forecast values';


--
-- TOC entry 290 (class 1259 OID 16948)
-- Name: chan; Type: TABLE; Schema: fc; Owner: -
--

CREATE TABLE chan (
    reason text,
    party text,
    frequency interval,
    fcst_basis text
);


--
-- TOC entry 12756 (class 0 OID 0)
-- Dependencies: 290
-- Name: TABLE chan; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON TABLE chan IS 'forecast channels and associated frequency and basis for forecasting';


--
-- TOC entry 2842 (class 1259 OID 82186)
-- Name: dble; Type: TABLE; Schema: fc; Owner: -
--

CREATE TABLE dble (
    flow text,
    party text,
    event text,
    flag text,
    account text,
    sign integer,
    vers text
);


--
-- TOC entry 12757 (class 0 OID 0)
-- Dependencies: 2842
-- Name: TABLE dble; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON TABLE dble IS 'event account assignment';


--
-- TOC entry 12758 (class 0 OID 0)
-- Dependencies: 2842
-- Name: COLUMN dble.flow; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN dble.flow IS 'work flow';


--
-- TOC entry 12759 (class 0 OID 0)
-- Dependencies: 2842
-- Name: COLUMN dble.party; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN dble.party IS 'party';


--
-- TOC entry 12760 (class 0 OID 0)
-- Dependencies: 2842
-- Name: COLUMN dble.event; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN dble.event IS 'work flow event';


--
-- TOC entry 12761 (class 0 OID 0)
-- Dependencies: 2842
-- Name: COLUMN dble.flag; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN dble.flag IS 'debit credit row creator';


--
-- TOC entry 12762 (class 0 OID 0)
-- Dependencies: 2842
-- Name: COLUMN dble.account; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN dble.account IS 'gl account';


--
-- TOC entry 12763 (class 0 OID 0)
-- Dependencies: 2842
-- Name: COLUMN dble.sign; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN dble.sign IS 'sign to apply to base number';


--
-- TOC entry 12764 (class 0 OID 0)
-- Dependencies: 2842
-- Name: COLUMN dble.vers; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN dble.vers IS 'forecast version';


--
-- TOC entry 2839 (class 1259 OID 82168)
-- Name: evnt; Type: TABLE; Schema: fc; Owner: -
--

CREATE TABLE evnt (
    flow text,
    driver text,
    factor numeric,
    vers text
);


--
-- TOC entry 12765 (class 0 OID 0)
-- Dependencies: 2839
-- Name: TABLE evnt; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON TABLE evnt IS 'forecasted work flows';


--
-- TOC entry 12766 (class 0 OID 0)
-- Dependencies: 2839
-- Name: COLUMN evnt.flow; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN evnt.flow IS 'work flow';


--
-- TOC entry 12767 (class 0 OID 0)
-- Dependencies: 2839
-- Name: COLUMN evnt.driver; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN evnt.driver IS 'driver';


--
-- TOC entry 12768 (class 0 OID 0)
-- Dependencies: 2839
-- Name: COLUMN evnt.factor; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN evnt.factor IS 'number to multiply by to get forecast of related item';


--
-- TOC entry 12769 (class 0 OID 0)
-- Dependencies: 2839
-- Name: COLUMN evnt.vers; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN evnt.vers IS 'forecast version';


--
-- TOC entry 2838 (class 1259 OID 82162)
-- Name: fcst; Type: TABLE; Schema: fc; Owner: -
--

CREATE TABLE fcst (
    driver text,
    perd tsrange,
    amount numeric,
    vers text
);


--
-- TOC entry 12770 (class 0 OID 0)
-- Dependencies: 2838
-- Name: TABLE fcst; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON TABLE fcst IS 'forecast drivers';


--
-- TOC entry 12771 (class 0 OID 0)
-- Dependencies: 2838
-- Name: COLUMN fcst.driver; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN fcst.driver IS 'forecasted driver';


--
-- TOC entry 12772 (class 0 OID 0)
-- Dependencies: 2838
-- Name: COLUMN fcst.perd; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN fcst.perd IS 'forecast date range';


--
-- TOC entry 12773 (class 0 OID 0)
-- Dependencies: 2838
-- Name: COLUMN fcst.amount; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN fcst.amount IS 'value or amount';


--
-- TOC entry 12774 (class 0 OID 0)
-- Dependencies: 2838
-- Name: COLUMN fcst.vers; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN fcst.vers IS 'version';


--
-- TOC entry 2840 (class 1259 OID 82174)
-- Name: party; Type: TABLE; Schema: fc; Owner: -
--

CREATE TABLE party (
    flow text,
    party text,
    split numeric,
    effr tsrange,
    freq interval,
    vers text
);


--
-- TOC entry 12775 (class 0 OID 0)
-- Dependencies: 2840
-- Name: TABLE party; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON TABLE party IS 'party share of forecasted flow';


--
-- TOC entry 2841 (class 1259 OID 82180)
-- Name: schd; Type: TABLE; Schema: fc; Owner: -
--

CREATE TABLE schd (
    flow text,
    party text,
    event text,
    seq integer,
    duration interval,
    vers text
);


--
-- TOC entry 12776 (class 0 OID 0)
-- Dependencies: 2841
-- Name: TABLE schd; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON TABLE schd IS 'party timing of flow events';


-- Completed on 2017-04-21 17:18:34

--
-- PostgreSQL database dump complete
--

