grammar Calculette;

@parser::members {

    private String evalexpr (String op) {
        if ( op.equals("*") ){
            return "MUL";
        } else if ( op.equals("+") ){
            return "ADD";
        } else if ( op.equals("-") ){
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
    : 
        NEWLINE*

        (instruction { $code += $instruction.code+"WRITE\nPOP\n"; })*

        { $code += "HALT\n"; }
    ;

instruction returns [ String code ]
    : expr finInstruction { $code = $expr.code; }
    | finInstruction
        {
            $code="";
        }
    ;

expr returns [ String code ]
    : '(' a=expr ')' { $code = $a.code; }
    | '+' a=expr { $code = $a.code; }
    | '-' a=expr { $code = "PUSHI 0\n"+$a.code+"SUB\n"; }
    | a=expr op=('*'|'/'|'%') b=expr { $code = $a.code+$b.code+evalexpr($op.text)+"\n"; }
    | a=expr op=('+'|'-') b=expr { $code = $a.code+$b.code+evalexpr($op.text)+"\n"; }
    | e=ENTIER { $code = "PUSHI "+$e.text+"\n"; }
    ;

finInstruction : ( NEWLINE | ';' )+ ;

// lexer
NEWLINE : ('\r'|'\n');

WS :   (' '|'\t')+ -> skip  ;

ENTIER : ('0'..'9')+  ;

UNMATCH : . -> skip ;
