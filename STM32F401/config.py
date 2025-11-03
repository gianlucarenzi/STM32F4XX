#!/usr/bin/env python3
"""
File di configurazione per KiCad Virtual Component Cleaner
===========================================================

Questo file contiene le impostazioni personalizzabili per il cleaner.
Modifica questi valori secondo le tue esigenze.
"""

# Pattern per identificare i file CSV CPL
CSV_PATTERNS = [
    "*_cpl_*.csv",      # Pattern standard KiCad
    "*_cpl.csv",        # Pattern alternativo
    "*_placement.csv",  # Pattern personalizzato
    "*_pick_place.csv", # Pattern JLCPCB
]

# Estensioni file PCB supportate
PCB_EXTENSIONS = [
    ".kicad_pcb",
    ".kicad_pcb_pro",  # Se usi versioni pro
]

# Prefisso per i file di backup
BACKUP_PREFIX = "backup_"

# Formato timestamp per backup
TIMESTAMP_FORMAT = "%Y%m%d_%H%M%S"

# Formato timestamp per report
REPORT_TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S"

# Nome del file di report
REPORT_FILENAME_TEMPLATE = "virtual_cleanup_report_{timestamp}.txt"

# Encoding per lettura/scrittura file
FILE_ENCODING = "utf-8"

# Separatore CSV (di solito virgola, ma può essere punto e virgola)
CSV_DELIMITER = ","

# Carattere di quote per CSV
CSV_QUOTECHAR = '"'

# Livelli di log disponibili
LOG_LEVELS = {
    "DEBUG": 10,
    "INFO": 20,
    "WARNING": 30,
    "ERROR": 40,
    "CRITICAL": 50
}

# Livello di log default
DEFAULT_LOG_LEVEL = "INFO"

# Colori per output terminale (ANSI escape codes)
COLORS = {
    "RED": "\033[0;31m",
    "GREEN": "\033[0;32m",
    "YELLOW": "\033[1;33m",
    "BLUE": "\033[0;34m",
    "PURPLE": "\033[0;35m",
    "CYAN": "\033[0;36m",
    "WHITE": "\033[1;37m",
    "NC": "\033[0m"  # No Color
}

# Messaggi personalizzabili
MESSAGES = {
    "BANNER": "KiCad Virtual Component Cleaner",
    "SUCCESS": "Operazione completata con successo!",
    "ERROR": "Operazione fallita!",
    "NO_VIRTUAL_FOUND": "Nessun oggetto virtuale trovato. Operazione terminata.",
    "NO_CSV_FOUND": "Nessun file CSV trovato",
    "NO_PCB_FOUND": "Nessun file .kicad_pcb trovato",
    "BACKUP_CREATED": "Backup creato",
    "FILE_PROCESSED": "File processato",
    "VIRTUAL_OBJECT_FOUND": "Trovato oggetto virtuale",
    "VIRTUAL_OBJECT_REMOVED": "Rimossa riga per oggetto virtuale"
}

# Attributi virtuali da cercare nel file PCB
# (normalmente solo "virtual", ma potresti voler aggiungere altri)
VIRTUAL_ATTRIBUTES = [
    "virtual",
    # "exclude_from_pos_files",  # Decommentare se necessario
    # "exclude_from_bom",        # Decommentare se necessario
]

# Pattern regex per estrarre i riferimenti dai moduli
REFERENCE_PATTERN = r'fp_text reference\s+(\S+)'

# Pattern regex per identificare i moduli
MODULE_PATTERN = r'\(module\s+'

# Pattern regex per identificare gli attributi virtuali
VIRTUAL_ATTR_PATTERN = r'\(attr\s+({})\)'.format('|'.join(VIRTUAL_ATTRIBUTES))

# Configurazione per il parsing del file PCB
PCB_PARSING = {
    "encoding": FILE_ENCODING,
    "chunk_size": 8192,  # Dimensione chunk per lettura file grandi
    "max_module_lines": 1000,  # Massimo numero di righe per modulo
}

# Configurazione per il processing CSV
CSV_PROCESSING = {
    "encoding": FILE_ENCODING,
    "delimiter": CSV_DELIMITER,
    "quotechar": CSV_QUOTECHAR,
    "skipinitialspace": True,
    "strict": True,
}

# Configurazione report
REPORT_CONFIG = {
    "include_timestamp": True,
    "include_file_paths": True,
    "include_removed_items": True,
    "include_statistics": True,
    "max_line_length": 80,
}

# Configurazione backup
BACKUP_CONFIG = {
    "create_backup": True,
    "backup_extension": ".backup",
    "include_timestamp": True,
    "max_backups": 10,  # Numero massimo di backup da mantenere
}

# Configurazione auto-rilevamento
AUTO_DETECTION = {
    "search_subdirectories": False,  # Cerca anche nelle sottodirectory
    "max_depth": 1,  # Profondità massima di ricerca
    "case_sensitive": False,  # Ricerca case-sensitive
}

# Configurazione validazione
VALIDATION = {
    "check_file_permissions": True,
    "check_file_size": True,
    "max_file_size_mb": 100,  # Dimensione massima file in MB
    "min_csv_columns": 2,  # Numero minimo di colonne nei CSV
}

# Configurazione performance
PERFORMANCE = {
    "use_multiprocessing": False,  # Usa multiprocessing per file grandi
    "max_workers": 4,  # Numero massimo di worker
    "chunk_processing": True,  # Processa file a chunk
}

# Configurazione debug
DEBUG = {
    "save_intermediate_files": False,  # Salva file intermedi per debug
    "verbose_parsing": False,  # Output verboso durante parsing
    "log_memory_usage": False,  # Log utilizzo memoria
}

# Funzione per caricare configurazione personalizzata
def load_custom_config(config_file="custom_config.py"):
    """
    Carica configurazione personalizzata da file esterno
    """
    import os
    import importlib.util
    
    if os.path.exists(config_file):
        try:
            spec = importlib.util.spec_from_file_location("custom_config", config_file)
            custom_config = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(custom_config)
            
            # Aggiorna le variabili globali con quelle personalizzate
            globals().update({
                key: value for key, value in vars(custom_config).items()
                if not key.startswith('_')
            })
            
            return True
        except Exception as e:
            print(f"Errore nel caricamento configurazione personalizzata: {e}")
            return False
    
    return False

# Carica configurazione personalizzata se esiste
load_custom_config()