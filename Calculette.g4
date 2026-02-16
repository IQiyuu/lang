grammar Calculette;

// antlr4 Calculette.g4
// javac *.java
// antlr4-grun Calculette start

@parser::members {
    private int _cur_label = 1;
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
}

start
    : calcul EOF 
    ;

calcul returns [ String code ]
@init{ $code = new String(); }   // On initialise une variable pour accumuler le code 
@after{ System.out.println($code); } // On affiche le code effectivement produit
    : (decl { $code += $decl.code; })*

        NEWLINE*

        (instruction { $code += $instruction.code; })*

        { $code += "HALT\n"; }
    ;

instruction returns [ String code ]
    : bloc finInstruction { $code = $bloc.code; }
    | expr finInstruction { $code = $expr.code; }
    | as=assignation finInstruction { $code = $as.code; }
    | 'put(' e=expr ')' finInstruction
    {
        $code = $e.code+"\nWRITE\n";
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
    | 'while(' c=condition ')' bloc finInstruction
    {
        newLabel();
        $code="LABEL Debut"+_cur_label+"\n"+$c.code+"JUMPF Fin"+_cur_label+$bloc.code;
    }
    | finInstruction
        {
            $code="";
        }
    ;

bloc returns [ String code ]  @init{ $code = new String(); } 
    : '{'
        NEWLINE*
        (decl { $code += $decl.code; })*

        NEWLINE*

        (instruction { $code += $instruction.code; })*
      '}'
      NEWLINE*
    ;

condition returns [String code]
    : 'True'  { $code = "  PUSHI 1\n"; }
    | 'False' { $code = "  PUSHI 0\n"; }
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
            System.out.println(vi.scope);
        }
    ;

expr returns [ String code ]
    : '(' a=expr ')' { $code = $a.code; }
    | '+' a=expr { $code = $a.code; }
    | '-' a=expr { $code = "PUSHI 0\n"+$a.code+"SUB\n"; }
    | a=expr op=('*'|'/'|'%') b=expr { $code = $a.code+$b.code+evalexpr($op.text)+"\n"; }
    | a=expr op=('+'|'-') b=expr { $code = $a.code+$b.code+evalexpr($op.text)+"\n"; }
    | ENTIER { $code = "PUSHI "+$ENTIER.text+"\n"; }
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
