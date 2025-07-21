# Conversor a formula bien formada (backend)

Este proyecto es una API construida en Ruby on Rails que expone un servicio que convierte cualquier fórmula lógica
escrita en LaTex en su fórmula bien formada (fbf) equivalente y entrega el resultado al front end: https://github.com/JuanCamiloPerilla/latex-processor-frontend
y al lista de pasos tomados para poder mostrarlos al usuario.

La implementación encargada de esta tarea se encuentra en `app/services/latex_proposition_parser.rb`. Este es un servicio
que realiza la reescritura en los siguientes pasos:
1. Tokeniza la expresión:

  ```ruby
  # Una proposición compuesta de latex recibida como parametro de la peticion se vería así
  "p \\rightarrow q \\leftrightarrow r \\lor ( s \\land p)"
  # Y al convertirse en tokens quedaría así: 
  ["p", "→", "q", "↔", "r", "∨", "(", "s", "∧", "p", ")"]
  ```
  Convertir la expresión en tokens tiene dos objetivos. 
  
  a. Reemplazar la sintaxis en latex por caracteres simples que puedan proveer una representación visual simple en forma de string
  para poder imprimirla con facilidad. Esto se logra con [gsub](https://apidock.com/ruby/String/gsub)
  
  b. Crear un arreglo de tokens que funcionará como entrada para el algoritmo shunting yard. El arreglo es creado a partir
  de la nueva expresión con [scan](https://apidock.com/ruby/String/scan)
  
2. Aplica el algoritmo [shunting yard](https://mathcenter.oxford.emory.edu/site/cs171/shuntingYardAlgorithm/) para reescribir el arreglo de tokens,
inicialmente representado en notación infija, a una representación en notación postfija equivalente.

(Implementación en: `backend/app/services/postfix_expression_builder.rb`)

 ```ruby
  # En notación infija inicia como:
  ["p", "→", "q", "↔", "r", "∨", "(", "s", "∧", "p", ")"]
  # Y al aplicar shunting yard quedaría en notación postfija como: 
  ["p", "q", "→", "r", "s", "p", "∧", "∨", "↔"]
  ```
Este paso tiene el objetivo de crear una estructura que represente con claridad la jerarquía de los operadores sin necesidad de utilizar paréntesis.
Esta condición facilita enormemente la construcción de un arbol.

3. Se construye un AST ([Arbol de Sintaxis Abstracta](https://en.wikipedia.org/wiki/Abstract_syntax_tree)) a partir de la expresión en notación postfija.
Para esta aplicación en particular, este arbol va a tener las siguientes características:

(Implementación encontrada en: `backend/app/services/postfix_to_ast.rb`)

  a. Cada nodo va a ser o bien un operador o bien un operando.
  b. Si es un operando, será un nodo terminal (hoja) y no tendrá nodos hijos (ramas)
  c. Si es un operador, tendrá dos nodos hijos (ramas), excepto para el caso de la negación.
  Cada nodo hijo puede ser o bien un operando o bien otro operador, por lo que, para el último caso,
  su nodo hijo tendrá otros nodos hijos.

Esta estructura va a permitir resolver al código recursivamente la jerarquía de cada operación y reescribir en latex asignando los paréntesis correctamente
para construir la fbf a partir de las precedencias escogidas por el usuario.

# Propósito

El propósito de este proyecto es mostrar al usuario el paso a paso de como el algoritmo escogido convierte la expresión a una expresión equivalente fácilmente computable, la expresión postfija, la transforma
en una estructura equivalente que representa sin ambiguedades la jerarquía y precedencia de operadores, el arbol de sintaxis abstracto y finalmente lo convierte en fórmula bien formada.

Además, la posibilidad de que el usuario escoja las precedencias de los operadores demuestra como este proceso puede extenderse y aplicarse a cualquier operador binario, no necesariamente a operadores logicos.

# Manual de usuario

La aplicación cuenta con una caja de texto donde se debe ingresar la fórmula lógica en sintaxis de latex. Debajo hay un panel que muestra la fórmula renderizada con símbolos de lates.
Bajo la vista del latex renderizado hay una tabla que permite asignar manualmente las precedencias de los operadores.

Una vez escogidas las precedencias y escrita la fórmula lógica, el botón procesar fórmula debe ser presionado.

<img width="1613" height="581" alt="image" src="https://github.com/user-attachments/assets/b196a36d-605b-471f-b79a-14ed96c79846" />


Al presionar el botón se mostrará la fórmula bien formada resultante:


<img width="1581" height="201" alt="image" src="https://github.com/user-attachments/assets/51691bac-f831-4f45-b778-084a90d595ad" />

Un panel mostrando el paso a paso de la construcción de la fórmula en notación postfija:

<img width="1611" height="576" alt="image" src="https://github.com/user-attachments/assets/c33eb895-ee2b-4ef8-bd95-f8207fb6d03e" />

Y un panel que permite al usuario navegar por el paso a paso con botonas la construcción del arbol:
<img width="1604" height="854" alt="image" src="https://github.com/user-attachments/assets/6caacc16-9d1a-4206-9394-0fde2e0cbdbf" />



