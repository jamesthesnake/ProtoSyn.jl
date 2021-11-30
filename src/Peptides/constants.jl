one_2_three = Dict{Char,String}(
    # '?' => "BKB",
    # 'A' => "ALA",
    # 'C' => "CYS",
    # 'D' => "ASP",
    # 'E' => "GLU",
    # 'F' => "PHE",
    # 'G' => "GLY",
    # 'H' => "HIS",
    # 'H' => "HIE",
    # 'I' => "ILE",
    # 'K' => "LYS",
    # 'L' => "LEU",
    # 'M' => "MET",
    # 'N' => "ASN",
    # 'P' => "PRO",
    # 'Q' => "GLN",
    # 'R' => "ARG",
    # 'S' => "SER",
    # 'T' => "THR",
    # 'V' => "VAL",
    # 'W' => "TRP",
    # 'Y' => "TYR",
)

three_2_one = Dict{String, Char}(
    # "BKB" => '?',
    # "ALA" => 'A',
    # "CYS" => 'C',
    # "ASP" => 'D',
    # "GLU" => 'E',
    # "PHE" => 'F',
    # "GLY" => 'G',
    # "HIS" => 'H',
    # "HIE" => 'H',
    # "ILE" => 'I',
    # "LYS" => 'K',
    # "LEU" => 'L',
    # "MET" => 'M',
    # "ASN" => 'N',
    # "PRO" => 'P',
    # "GLN" => 'Q',
    # "ARG" => 'R',
    # "SER" => 'S',
    # "THR" => 'T',
    # "VAL" => 'V',
    # "TRP" => 'W',
    # "TYR" => 'Y',
)


const doolitle_hydrophobicity = Dict{String, ProtoSyn.Units.defaultFloat}(
    "ILE" =>  4.5,
    "VAL" =>  4.2,
    "LEU" =>  3.8,
    "PHE" =>  2.8,
    "CYS" =>  2.5,
    "MET" =>  1.9,
    "ALA" =>  1.8,
    "GLY" => -0.4,
    "THR" => -0.7,
    "SER" => -0.8,
    "TRP" => -0.9,
    "TYR" => -1.3,
    "PRO" => -1.6,
    "HIS" => -3.2,
    "HIE" => -3.2,
    "ASN" => -3.5,
    "GLU" => -3.5,
    "GLN" => -3.5,
    "ASP" => -3.5,
    "LYS" => -3.9,
    "ARG" => -4.5
)

const doolitle_hydrophobicity_mod1 = Dict{String, ProtoSyn.Units.defaultFloat}(
    "ILE" =>  5.5,
    "VAL" =>  5.2,
    "LEU" =>  4.8,
    "PHE" =>  3.8,
    "CYS" =>  3.5,
    "MET" =>  2.9,
    "ALA" =>  2.8,
    "GLY" => -0.4,
    "THR" => -0.7,
    "SER" => -0.8,
    "TRP" => -0.9,
    "TYR" => -1.3,
    "PRO" => -1.6,
    "HIS" => -3.2,
    "HIE" => -3.2,
    "ASN" => -3.5,
    "GLN" => -3.5,
    "ASP" => -3.5,
    "GLU" => -3.5,
    "LYS" => -3.9,
    "ARG" => -4.5
)

const doolitle_hydrophobicity_mod2 = Dict{String, ProtoSyn.Units.defaultFloat}(
    "ILE" =>  6.5,
    "VAL" =>  6.2,
    "LEU" =>  5.8,
    "PHE" =>  4.8,
    "CYS" =>  4.5,
    "MET" =>  3.9,
    "ALA" =>  3.8,
    "GLY" => -0.4,
    "THR" => -0.7,
    "SER" => -0.8,
    "TRP" => -0.9,
    "TYR" => -1.3,
    "PRO" => -1.6,
    "HIS" => -3.2,
    "HIE" => -3.2,
    "ASN" => -3.5,
    "GLN" => -3.5,
    "ASP" => -3.5,
    "GLU" => -3.5,
    "LYS" => -3.9,
    "ARG" => -4.5
)

const doolitle_hydrophobicity_mod3 = Dict{String, ProtoSyn.Units.defaultFloat}(
    "ILE" =>  7.5,
    "VAL" =>  7.2,
    "LEU" =>  6.8,
    "PHE" =>  5.8,
    "CYS" =>  5.5,
    "MET" =>  4.9,
    "ALA" =>  4.8,
    "GLY" => -0.4,
    "THR" => -0.7,
    "SER" => -0.8,
    "TRP" => -0.9,
    "TYR" => -1.3,
    "PRO" => -1.6,
    "HIS" => -3.2,
    "HIE" => -3.2,
    "ASN" => -3.5,
    "GLN" => -3.5,
    "ASP" => -3.5,
    "GLU" => -3.5,
    "LYS" => -3.9,
    "ARG" => -4.5
)

const doolitle_hydrophobicity_mod7 = Dict{String, ProtoSyn.Units.defaultFloat}(
    "ILE" =>  11.5,
    "VAL" =>  11.2,
    "LEU" =>  10.8,
    "PHE" =>  9.8,
    "CYS" =>  9.5,
    "MET" =>  8.9,
    "ALA" =>  8.8,
    "GLY" => -0.4,
    "THR" => -0.7,
    "SER" => -0.8,
    "TRP" => -0.9,
    "TYR" => -1.3,
    "PRO" => -1.6,
    "HIS" => -3.2,
    "HIE" => -3.2,
    "ASN" => -3.5,
    "GLN" => -3.5,
    "ASP" => -3.5,
    "GLU" => -3.5,
    "LYS" => -3.9,
    "ARG" => -4.5
)


const doolitle_hydrophobicity_extreme = Dict{String, ProtoSyn.Units.defaultFloat}(
    "ILE" => 11.5,
    "VAL" => 11.2,
    "LEU" => 10.8,
    "PHE" => 9.8,
    "CYS" => 9.5,
    "MET" => 8.9,
    "ALA" => 8.8,
    "GLY" => 0.0,
    "THR" => 0.0,
    "SER" => 0.0,
    "TRP" => 0.0,
    "TYR" => 0.0,
    "PRO" => 0.0,
    "HIS" => 0.0,
    "HIE" => 0.0,
    "ASN" => 0.0,
    "GLN" => 0.0,
    "ASP" => 0.0,
    "GLU" => 0.0,
    "LYS" => 0.0,
    "ARG" => 0.0
)

available_aminoacids = Dict{Char, Bool}(
    # 'M' => true,
    # 'K' => true,
    # 'P' => true,
    # 'Q' => true,
    # 'I' => true,
    # 'H' => true,
    # 'E' => true,
    # 'W' => true,
    # 'S' => true,
    # 'T' => true,
    # 'C' => true,
    # 'D' => true,
    # 'A' => true,
    # 'L' => true,
    # 'Y' => true,
    # 'V' => true,
    # 'R' => true,
    # 'G' => true,
    # 'F' => true,
    # 'N' => true
)

const polar_residues = ["ARG", "ASN", "ASP", "GLU", "GLN", "HIS", "LYS", "SER", "THR", "TYR"]