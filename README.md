# Latex Processor Backend

Este proyecto es una API construida en Ruby on Rails que expone un servicio que convierte cualquier fórmula lógica
escrita en LaTex en su fórmula bien formada (fbf) equivalente.

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
  a. Cada nodo va a ser o bien un operador o bien un operando.
  b. Si es un operando, será un nodo terminal (hoja) y no tendrá nodos hijos (ramas)
  c. Si es un operador, tendrá dos nodos hijos (ramas), excepto para el caso de la negación.
  Cada nodo hijo puede ser o bien un operando o bien otro operador, por lo que, para el último caso,
  su nodo hijo tendrá otros nodos hijos.

Esta estructura va a permitir resolver al código recursivamente la jerarquía de cada operación y reescribir en latex asignando los paréntesis correctamente
para construir la fbf a partir de las precedencias escogidas por el usuario.


