# ── Word categories ─────────────────────────────────────────
CATEGORIES = {
  "Household Items" => %w[
    refrigerator microwave dishwasher pillowcase curtains
    bookshelf lampshade broom dustpan colander spatula
    tablecloth wardrobe cabinet toaster blender kettle
    cushion mattress doorbell saucepan utensil napkin
    fireplace chandelier console wallpaper escalator
    banister countertop furnace thermostat plunger
  ],
  "Tanks" => %w[
    abrams leopard challenger panzer tiger sherman
    pershing centurion merkava crusader chieftain firefly
    matilda panther hellcat stug sturmtiger ferdinand
    hetzer panzerkampfwagen t34 t44 t54 kv vickers
    conqueror tortoise jaegerb archer cromwell cromwell
  ],
  "Utilities" => %w[
    electricity plumbing broadband sewage heating
    waterworks gasline telephone recycling drainage
    transformer substation reservoir pipeline generator
    powerline conduit faucet septic aqueduct gridlock
    turbine hydroelectric geothermal windmill
  ],
  "Animals" => %w[
    hippopotamus chimpanzee rhinoceros salamander crocodile
    armadillo platypus chameleon flamingo porcupine
    wolverine albatross jellyfish giraffe elephant
    ostrich pangolin tapir anteater ferret meerkat
    capybara orangutan gibbon antelope impala warthog
    cheetah lynx aardvark skunk badger lemur tarsier
  ],
  "Countries" => %w[
    mozambique kazakhstan liechtenstein azerbaijan madagascar
    switzerland philippines uzbekistan cambodia venezuela
    argentina indonesia guatemala dominican mauritius
    singapore laos latvia estonia turkmenistan tajikistan
    kyrgyzstan montenegro luxembourg malta cyprus samoa
  ],
  "Space" => %w[
    nebula asteroid comet galaxy pulsar supernova blackhole
    quasar telescope satellite cosmonaut trajectory atmosphere
    exoplanet orbit supergiant redgiant whitedwarf neutron
    aurora constellation zodiac eclipse solar lunar eclipse
    andromeda orion cygnus draco ursa vega sirius altair
  ],
  "Dinosaurs" => %w[
    tyrannosaurus triceratops stegosaurus brachiosaurus
    velociraptor parasaurolophus ankylosaurus iguanodon
    spinosaurus allosaurus carnotaurus therizinosaurus
    diplodocus apatosaurus brachiosaurus deinonychus
    compsognathus ostracoderms archaeopteryx
  ],
  "Mythology" => %w[
    zeus athena apollo artemis aphrodite hermes hades
    poseidon ares hephaestus demeter hera dionysus
    minotaur centaur pegasus chimera phoenix cyclops
    medusa cerberus sphinx gorgon harpy siren nymph
    valkyrie golem basilisk banshee kraken leviathan
  ],
  "Musical Instruments" => %w[
    saxophone trumpet trombone clarinet tuba violin
    cello viola guitar mandolin ukulele harp piano
    accordion xylophone marimba timpani cymbal tambourine
    harmonica synthesizer flute oboe bassoon piccolo
    metronome gong bugle cornet euphonium sousaphone
  ],
  "Technology" => %w[
    computer laptop smartphone tablet monitor keyboard
    mouse router modem processor graphics memory
    motherboard power circuit database algorithm
    software hardware firmware application encryption
    javascript typescript python cryptocurrency blockchain
  ],
  "Foods & Cuisine" => %w[
    spaghetti lasagna pizza paella risotto burritos
    tacos enchiladas dumplings ramen noodles sashimi
    tiramisu bruschetta croissant escargot schnitzel
    goulash stroganoff pierogi borsch gazpacho ceviche
    poutine hamburger hotdog carbonara bolognese chowder
  ],
  "Landmarks & Monuments" => %w[
    pyramids colosseum parthenon statue liberty tower
    eiffel bigben burjkhalifa chrysler empire domtower
    sagrada familia westminster alhambra versailles
    machu picchu angkor stonehenge moai taj mahaj
  ],
  "Gemstones & Minerals" => %w[
    diamond sapphire emerald ruby amethyst topaz
    garnet opal turquoise obsidian jade lapis malachite
    quartz feldspar mica magnetite hematite limestone
    marble granite slate talc asbestos fluorite
  ],
  "Sports" => %w[
    basketball football baseball cricket volleyball
    badminton tennis racquetball squash golf hockey
    lacrosse curling singleskatebowling billiards archery
    fencing wrestling judo karate taekwondo sumo
    weightlifting gymnastics skiing snowboarding sledding
  ]
}

# ── ASCII hangman stages ─────────────────────────────────────
HANGMAN = [
  "    ________\n    |      |\n    |\n    |\n    |\n    |\n  __|__",
  "    ________\n    |      |\n    |      O\n    |\n    |\n    |\n  __|__",
  "    ________\n    |      |\n    |      O\n    |      |\n    |\n    |\n  __|__",
  "    ________\n    |      |\n    |      O\n    |     /|\n    |\n    |\n  __|__",
  "    ________\n    |      |\n    |      O\n    |     /|\\\n    |\n    |\n  __|__",
  "    ________\n    |      |\n    |      O\n    |     /|\\\n    |     /\n    |\n  __|__",
  "    ________\n    |      |\n    |      O\n    |     /|\\\n    |     / \\\n    |\n  __|__"
]

BASE_MAX_WRONG = 6

# ── Slot Machine Symbols ────────────────────────────────────
SLOT_SYMBOLS = [
  { name: "7",      display: Color.bold(Color.yellow(" 7 ")),   weight: 5  },
  { name: "BAR",    display: Color.bold(Color.white("BAR")),    weight: 10 },
  { name: "BELL",   display: Color.bold(Color.yellow("BEL")),   weight: 15 },
  { name: "STAR",   display: Color.bold(Color.cyan(" * ")),     weight: 20 },
  { name: "CHERRY", display: Color.bold(Color.red(" C ")),      weight: 25 },
  { name: "LEMON",  display: Color.bold(Color.yellow(" L ")),   weight: 25 },
].freeze

# ── Dev Passcode ───────────────────────────────────────────
DEV_PASSCODE = "I_LOVE_CISCO"
