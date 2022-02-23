+++
author = "Dheepak Krishnamurthy"
mintoclevel = 2
ignore = ["node_modules/"]
hasmath = true
generate_rss = true
website_title = "SIIP Tutorial"
website_descr = "Website for SIIP Tutorial"
website_url = "NREL-SIIP/github.io/SIIP-Tutorial/"
+++


\newcommand{\fieldset}[3]{
  ~~~
  <fieldset class="#1"><legend class="#1-legend">#2</legend>
  ~~~
  #3
  ~~~
  </fieldset>
  ~~~
}

<!--
  Tip
-->
\newcommand{\tip}[1]{
  \fieldset{tip}{💡 Tip}{
    #1
  }
}

<!--
 Todo
-->
\newcommand{\todo}[1]{
  \fieldset{todo}{🚧 To Do}{
    #1
  }
}

<!--
 Note
-->
\newcommand{\note}[1]{
  \fieldset{note}{📝 Note}{
    #1
  }
}

<!--
 Exercise
-->
\newcommand{\exercise}[1]{
  \fieldset{exercise}{🏋  Exercise}{
    #1
  }
}

<!-- collapse -->
\newcommand{\collapse}[2]{
~~~<button type="button" class="collapsible">~~~ #1 ~~~</button><div class="collapsiblecontent">~~~ #2 ~~~</div>~~~
}
