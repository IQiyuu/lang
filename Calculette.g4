grammar Calculette;

// antlr4 Calculette.g4
// javac *.java
// antlr4-grun Calculette start

@parser::members {
    private int _cur_label = 0;
    private String newLabel( ) { return "Label"+(_cur_label++); };
    private TablesSymboles tablesSymboles = new TablesSymboles();

    private String evalexpr (String op) {
        if ( op.equals("*") ){
            return "MUL";
        } else if ( op.equals("+") || op.equals("++")){
            return "ADD";
        } else if ( op.equals("-") || op.equals("--")){
            return "SUB";
        } else if ( op.equals("/") ){
            return "DIV";
        } else if ( op.equals("%") ){
            return "MOD";
        } else {
           System.err.println("Opérateur arithmétique incorrect : '"+op+"'");
           throw new IllegalArgumentException("Opérateur arithmétique incorrect : '"+op+"'");
        }
    }

    private String evalCond (String op) {
        if ( op.equals("==") ) {
            return "EQUAL";
        } else if (op.equals("!=")){
            return "EQUAL\nPUSHI 0\nEQUAL\n";
        }else if ( op.equals(">") ) {
            return "SUP";
        } else if ( op.equals(">=") ) {
            return "SUPEQ";
        } else if ( op.equals("<") ) {
            return "INF";
        } else if ( op.equals("<=") ) {
            return "INFEQ";
        } else {
            return "";
        }
    }
}

start
    : calcul EOF 
    ;

calcul returns [ String code ]
@init{ $code = new String(); }   // On initialise une variable pour accumuler le code 
@after{ System.out.println($code); } // On affiche le code effectivement produit
    : (decl { $code += $decl.code; })*
        { $code += "JUMP Start\n"; }

        NEWLINE*

        (fonction { $code += $fonction.code; })*

        NEWLINE*

        { $code += "LABEL Start\n"; }
        (instruction { $code += $instruction.code; })*

        { $code += "HALT\n"; }
    ;

instruction returns [ String code ]
    : bloc finInstruction { $code = $bloc.code; }
    | expr finInstruction { $code = $expr.code; }
    | as=assignation finInstruction { $code = $as.code; }
    | 'put(' e=expr ')' finInstruction
    {
        $code = $e.code+"WRITE\nPOP\n";
    }
    | 'get(' IDENTIFIANT ')' finInstruction
    {
        VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
        $code = "READ\nSTOREG "+vi.address+"\n";
    }
    | IDENTIFIANT op=('++'|'--')
    {
        VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
        $code = "PUSHG "+vi.address+"\nPUSHI 1\n"+evalexpr($op.text)+"\nSTOREG "+vi.address+"\n";
    }
    | i=ifbloc { $code = $i.code; }
    | w=whilebloc { $code = $w.code; }
    | f=forbloc { $code = $f.code; }
    | finInstruction
        {
            $code="";
        }
    ;

fonction returns [ String code ]
    : type=TYPEV ':=' nom=IDENTIFIANT
        {
            $code="LABEL "+$nom.text+"\n";
            tablesSymboles.addFunction($nom.text,$type.text);
        }
        '('  ')' b=bloc
        {
            $code+=$b.code
                +"RETURN\n";  //  Return "de sécurité"
        }
    ;

forbloc returns [ String code ]
    : 'for' '(' a1=assignation ';' c=condition ';' a2=assignation ')' i=instruction
    {
        newLabel();
        String l1 = "DebutFor"+_cur_label+"\n";
        String l2 = "FinFor"+_cur_label+"\n";
        $code=$a1.code
            +"LABEL "+l1
            +$c.code
            +"JUMPF "+l2
            +$i.code
            +$a2.code
            +"JUMP "+l1
            +"LABEL "+l2;
    }
    ;

ifbloc returns [ String code ]
    : 'if' '(' c=condition ')' 'then' blocthen=instruction 'else' blocelse=instruction
    {
        newLabel();
        String l1 = "Else"+_cur_label+"\n";
        String l2 = "FinElse"+_cur_label+"\n";
        $code=$c.code
            +"JUMPF "+l1
            +$blocthen.code
            +"JUMP "+l2
            +"LABEL "+l1
            +$blocelse.code+"LABEL "+l2;
    }
    | 'if' '(' c=condition ')' 'then' blocthen=instruction
    {
        newLabel();
        String l1 = "FinElse"+_cur_label+"\n";
        $code=$c.code
            +"JUMPF "+l1
            +$blocthen.code
            +"LABEL "+l1;
    }
    ;

whilebloc returns [ String code ]
    : 'while' '(' c=condition ')' i=instruction
    {
        newLabel();
        String l1 = "DebutWhile"+_cur_label+"\n";
        String l2 = "FinWhile"+_cur_label+"\n";
        $code="LABEL "+l1
            +$c.code
            +"JUMPF "+l2
            +$i.code
            +"JUMP "+l1
            +"LABEL "+l2;
    }
    ;

bloc returns [ String code ]  @init{ $code = new String(); } 
    : '{'
        NEWLINE*
        (instruction { $code += $instruction.code; })*
        NEWLINE*
      '}'
    ;

condition returns [String code]
    : 'True'  { $code = "PUSHI 1\n"; }
    | 'False' { $code = "PUSHI 0\n"; }
    | '(' c=condition ')' { $code = $c.code; }
    | e1=expr op=('<'|'<='|'>='|'>'|'=='|'!=') e2=expr
    {
        $code = $e1.code
            +$e2.code
            +evalCond($op.text)+"\n";
    }
    | 'not' c=condition {
        $code = $c.code+"PUSHI 0\nEQUAL\n";
    }
    | c1=condition 'and' c2=condition {
        $code = $c1.code
        +$c2.code
        +"MUL\n";
    }
    | c1=condition 'or' c2=condition {
        $code = $c1.code
        +$c2.code
        +"ADD\nPUSHI 1\nSUPEQ\n";
    }
    ;


decl returns [ String code ]
    : IDENTIFIANT '::' TYPEV finInstruction
        {
            tablesSymboles.addVarDecl($IDENTIFIANT.text,$TYPEV.text);
            $code = "PUSHI 0\n";
        }
    | IDENTIFIANT '=' e=expr '::' TYPEV finInstruction
        {
            tablesSymboles.addVarDecl($IDENTIFIANT.text,$TYPEV.text);
            $code = $e.code;
        }
    ;

assignation returns [ String code ] 
    : IDENTIFIANT '=' e=expr
        {
            VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
            $code = $e.code+"STOREG "+vi.address+"\n";
        }
    ;

expr returns [ String code, String type ]
    : '(' a=expr ')' { $code = $a.code; }
    | '+' a=expr { $code = $a.code; }
    | '-' a=expr { $code = "PUSHI 0\n"+$a.code+"SUB\n"; }
    | a=expr op=('*'|'/'|'%') b=expr { $code = $a.code+$b.code+evalexpr($op.text)+"\n"; }
    | a=expr op=('+'|'-') b=expr { $code = $a.code+$b.code+evalexpr($op.text)+"\n"; }
    | ENTIER { $code = "PUSHI "+$ENTIER.text+"\n"; }
    | nom=IDENTIFIANT '('')'
    {
        String f = tablesSymboles.getFunction($nom.text);
        if (f != null) {
            tablesSymboles.enterFunction();
            $type=f;
            $code="CALL "+$nom.text+"\n";
        }
    }
    | IDENTIFIANT
    {
        VariableInfo v = tablesSymboles.getVar($IDENTIFIANT.text);
        $code = "PUSHG "+v.address+"\n";
    }
    ;

finInstruction : ( NEWLINE | ';' )+ ;

// lexer
NEWLINE : ('\r'|'\n');

TYPEV : 'int' | 'float' ;

WS :   (' '|'\t')+ -> skip  ;

ENTIER : ('0'..'9')+  ;

IDENTIFIANT : ('a'..'z')+ ;

COMMENT : '//' ~[\r\n]* -> skip ;

MULTICOMMENT : '/*' .*? '*/' -> skip ;

UNMATCH : . -> skip ;
