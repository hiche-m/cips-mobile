String capFix(String text) {
  String s, newText;
  text = text + " ";
  while (text[0] == ' ') {
    text = text.substring(1);
  }
  try {
    s = fixSpaces(text.substring(text.indexOf(" ")));
  } catch (e) {
    s = "";
  }
  newText = capFixWord(text.substring(0, text.indexOf(" ")), true);

  while (true) {
    try {
      String word = capFixWord(
          s.substring(s.indexOf(" "), s.indexOf(" ", s.indexOf(" ") + 1)),
          false);
      newText = newText + fixSpaces(word);
      s = fixSpaces(s.substring(s.indexOf(" ", s.indexOf(" ") + 1), s.length));
    } catch (e) {
      break;
    }
  }
  return newText;
}

String capFixWord(String text, bool firstMode) {
  return firstMode
      ? text.substring(0, 1).toUpperCase() + text.substring(1).toLowerCase()
      : text.substring(0, text.indexOf(" ") + 2).toUpperCase() +
          text.substring(text.indexOf(" ") + 2).toLowerCase();
}

String fixSpaces(String text) {
  while (text[text.indexOf(" ") + 1] == " ") {
    text = text.substring(0, text.indexOf(" ")) +
        text.substring(text.indexOf(" ") + 1);
  }

  return text;
}

String firstWordWithNoSpaces(String text) {
  text += " ";
  text = text.substring(0, text.indexOf(" "));

  return text;
}
