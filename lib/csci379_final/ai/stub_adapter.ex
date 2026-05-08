defmodule Csci379Final.AI.StubAdapter do
  @behaviour Csci379Final.AI.GeneratorPort

  @impl true
  def generate_story(_topic) do
    {:ok,
     %{
       "title" => "The Roman Empire",
       "chapters" => [
         %{
           "title" => "Chapter 1: The Rise of Rome",
           "description" => "From a small city-state to a Mediterranean superpower.",
           "scenes" => [
             %{
               "title" => "Scene 1: The Founding",
               "description" => "Legend and history of Rome's origins.",
               "quests" => [
                 %{
                   "type" => "multiple_choice",
                   "question" => "According to legend, who founded Rome?",
                   "options" => %{"a" => "Romulus", "b" => "Remus", "c" => "Julius Caesar", "d" => "Augustus"},
                   "correct_answer" => "a",
                   "explanation" => "Romulus is said to have founded Rome in 753 BC."
                 },
                 %{
                   "type" => "fill_blank",
                   "question" => "Rome was traditionally founded in ___ BC.",
                   "options" => nil,
                   "correct_answer" => "753",
                   "explanation" => "753 BC is the traditional founding date of Rome."
                 },
                 %{
                   "type" => "short_answer",
                   "question" => "Why was the location of Rome on the Tiber River strategically important?",
                   "options" => nil,
                   "correct_answer" => "It allowed trade and defense while remaining close to the sea.",
                   "explanation" => "The Tiber provided fresh water, trade routes, and a natural defensive barrier."
                 }
               ]
             },
             %{
               "title" => "Scene 2: The Republic",
               "description" => "How Rome evolved from a monarchy to a republic.",
               "quests" => [
                 %{
                   "type" => "multiple_choice",
                   "question" => "The Roman Republic was governed by which body?",
                   "options" => %{"a" => "The Senate", "b" => "The Emperor", "c" => "The Consuls only", "d" => "The Patricians"},
                   "correct_answer" => "a",
                   "explanation" => "The Senate was the dominant governing body of the Roman Republic."
                 },
                 %{
                   "type" => "fill_blank",
                   "question" => "The two chief magistrates of the Roman Republic were called ___.",
                   "options" => nil,
                   "correct_answer" => "consuls",
                   "explanation" => "Two consuls were elected each year to lead the Republic."
                 },
                 %{
                   "type" => "short_answer",
                   "question" => "What was the main advantage of having two consuls instead of one ruler?",
                   "options" => nil,
                   "correct_answer" => "It prevented any single person from gaining too much power.",
                   "explanation" => "Each consul could veto the other, creating a checks-and-balances system."
                 }
               ]
             }
           ]
         },
         %{
           "title" => "Chapter 2: The Empire",
           "description" => "Julius Caesar, Augustus, and the transformation into an empire.",
           "scenes" => [
             %{
               "title" => "Scene 1: Julius Caesar",
               "description" => "The general who changed Rome forever.",
               "quests" => [
                 %{
                   "type" => "multiple_choice",
                   "question" => "Julius Caesar was assassinated on which date?",
                   "options" => %{"a" => "March 15, 44 BC", "b" => "January 1, 45 BC", "c" => "December 25, 43 BC", "d" => "April 3, 44 BC"},
                   "correct_answer" => "a",
                   "explanation" => "Caesar was assassinated on the Ides of March, 44 BC."
                 },
                 %{
                   "type" => "fill_blank",
                   "question" => "Julius Caesar crossed the ___ river, triggering a civil war.",
                   "options" => nil,
                   "correct_answer" => "Rubicon",
                   "explanation" => "Crossing the Rubicon with his army was an act of war against the Senate."
                 },
                 %{
                   "type" => "short_answer",
                   "question" => "Why did senators conspire to kill Julius Caesar?",
                   "options" => nil,
                   "correct_answer" => "They feared he would make himself king and end the Republic.",
                   "explanation" => "Caesar's growing power and popular support threatened the Republican system."
                 }
               ]
             },
             %{
               "title" => "Scene 2: Augustus and the Pax Romana",
               "description" => "The first emperor and Rome's golden age.",
               "quests" => [
                 %{
                   "type" => "multiple_choice",
                   "question" => "What does 'Pax Romana' mean?",
                   "options" => %{"a" => "Roman Peace", "b" => "Roman Power", "c" => "Roman Law", "d" => "Roman Glory"},
                   "correct_answer" => "a",
                   "explanation" => "Pax Romana means 'Roman Peace', a period of relative stability across the empire."
                 },
                 %{
                   "type" => "fill_blank",
                   "question" => "Augustus was the ___ Emperor of Rome.",
                   "options" => nil,
                   "correct_answer" => "first",
                   "explanation" => "Augustus (formerly Octavian) became Rome's first emperor in 27 BC."
                 },
                 %{
                   "type" => "short_answer",
                   "question" => "How did Augustus maintain power while keeping the appearance of the Republic?",
                   "options" => nil,
                   "correct_answer" => "He held multiple Republican offices simultaneously and controlled the army.",
                   "explanation" => "Augustus was careful never to call himself king, instead accumulating Republican titles."
                 }
               ]
             }
           ]
         }
       ]
     }}
  end

  @impl true
  def grade_answer(_question, _user_answer) do
    {:ok, %{is_correct: true, feedback: "Good answer!"}}
  end
end
