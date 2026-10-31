import 'dart:math';

import '../models/content_catalog.dart';
import '../models/environment_mode.dart';

class DiscoveryPack {
  final String curiosity;
  final List<String> wowDiscoveries;
  final List<String> mysteryClues;
  final List<String> whatIfPrompts;
  final List<String> whatIfChoices;
  final String whatIfAnswer;
  final List<String> surpriseIds;
  final List<String> relatedIds;
  final String reaction;

  const DiscoveryPack({
    required this.curiosity,
    required this.wowDiscoveries,
    required this.mysteryClues,
    required this.whatIfPrompts,
    required this.whatIfChoices,
    required this.whatIfAnswer,
    required this.surpriseIds,
    required this.relatedIds,
    required this.reaction,
  });
}

class SurpriseEvent {
  final String id;
  final String title;
  final String message;
  final String emoji;
  const SurpriseEvent(this.id, this.title, this.message, this.emoji);
}

class DiscoveryEngine {
  DiscoveryEngine._();

  static final Map<String, DiscoveryPack> _packs = {
    'apple': const DiscoveryPack(
      curiosity: 'Look closely at the little dip at the top. An apple has more going on than its shiny skin!',
      wowDiscoveries: [
        'An apple begins as a flower. The flower is the tiny beginning of the fruit.',
        'An apple has tiny air spaces inside, which is one reason a fresh apple can be surprisingly light for its size.',
        'The star-shaped pattern you can see when an apple is cut across the middle hides its seeds.',
      ],
      mysteryClues: [
        'I can grow on a tree.',
        'I can be red, green or yellow.',
        'Cut me across the middle and look for a tiny star.',
      ],
      whatIfPrompts: [
        'What do you think will happen if an apple is placed in water?',
      ],
      whatIfChoices: [
        'It may float',
        'It will turn into a flower',
        'It will disappear',
      ],
      whatIfAnswer: 'A whole apple can float because its shape and the air spaces inside make it less dense than water.',
      surpriseIds: ['apple_star_cut', 'apple_seed_secret', 'butterfly_follow'],
      relatedIds: ['flower', 'water', 'tree'],
      reaction: 'The apple twinkles and a tiny seed-shaped trail appears.',
    ),
    'banana': const DiscoveryPack(
      curiosity: 'Why does a banana curve? Vee thinks the answer is hiding in the way the fruit grows.',
      wowDiscoveries: [
        'Bananas grow in bunches, and the fruits curve as they grow toward light.',
        'The banana plant is not a tree in the usual woody sense. It grows from a giant leafy stem.',
        'A banana peel changes color as the fruit ripens, giving you a visible clue about its stage.',
      ],
      mysteryClues: [
        'I grow in a bunch.',
        'I can change from green toward yellow.',
        'My fruit has a funny curve.',
      ],
      whatIfPrompts: [
        'What would happen if a green banana stayed on the plant longer?',
      ],
      whatIfChoices: [
        'It would ripen',
        'It would become a rock',
        'It would lose its peel',
      ],
      whatIfAnswer: 'As a banana ripens, its color and texture change and it becomes softer and sweeter.',
      surpriseIds: ['banana_bunch', 'banana_color_shift', 'hidden_seed_trail'],
      relatedIds: ['water', 'flower', 'apple'],
      reaction: 'A banana peel wiggles open just a little and Vee spots a color clue.',
    ),
    'tomato': const DiscoveryPack(
      curiosity: 'A tomato looks simple outside. Inside, it is packed with tiny chambers and seeds.',
      wowDiscoveries: [
        'Tomatoes develop from flowers on the plant.',
        'A tomato can have several little chambers holding seeds inside.',
        'Tomatoes come in many shapes and colors, not just the familiar red one.',
      ],
      mysteryClues: [
        'I can be red, yellow or green.',
        'I grow on a plant.',
        'I hide many seeds inside.',
      ],
      whatIfPrompts: [
        'What might you notice if you cut a tomato across the middle?',
      ],
      whatIfChoices: ['Seed chambers', 'A tiny butterfly', 'A hard stone'],
      whatIfAnswer:
          'You can see chambers filled with seeds and juicy material.',
      surpriseIds: ['tomato_seed_map', 'color_shift', 'garden_bloom'],
      relatedIds: ['flower', 'leaf', 'water'],
      reaction:
          'Tiny seed dots light up like a constellation inside the tomato.',
    ),
    'carrot': const DiscoveryPack(
      curiosity:
          'Most of the carrot is hiding where you cannot see it: underground!',
      wowDiscoveries: [
        'The orange part we eat is a root that stores energy for the plant.',
        'Carrot leaves grow above the soil while the root stays hidden below it.',
        'Carrots can come in colors other than orange, including purple and yellow.',
      ],
      mysteryClues: [
        'Part of me grows underground.',
        'My leaves can be seen above the soil.',
        'I can be orange, purple or yellow.',
      ],
      whatIfPrompts: [
        'What would happen if we gently brushed the soil away around a carrot?',
      ],
      whatIfChoices: [
        'We could reveal the hidden root',
        'It would fly away',
        'It would become a flower',
      ],
      whatIfAnswer: 'You could reveal the root growing below the soil while the leafy part stays above it.',
      surpriseIds: ['carrot_underground', 'hidden_root', 'garden_tunnel'],
      relatedIds: ['leaf', 'water', 'flower'],
      reaction: 'The ground opens into a tiny peek-hole and Vee discovers an underground root.',
    ),
    'flower': const DiscoveryPack(
      curiosity:
          'This flower may be doing a quiet job while it looks beautiful.',
      wowDiscoveries: [
        'Many flowers are built to attract pollinators with color, shape, scent or nectar.',
        'A flower can be part of the plant’s seed-making story, not just decoration.',
        'Some flowers change how open they are as light and conditions change.',
      ],
      mysteryClues: [
        'I can attract tiny visitors.',
        'I can have bright colors.',
        'I can help a plant make seeds.',
      ],
      whatIfPrompts: ['What might happen if a butterfly visits a flower?'],
      whatIfChoices: [
        'It may pick up or leave pollen',
        'The flower becomes a rock',
        'The butterfly disappears',
      ],
      whatIfAnswer: 'A visiting pollinator can move pollen between flowers, helping many plants make seeds.',
      surpriseIds: ['butterfly_follow', 'flower_bloom', 'hidden_pollen'],
      relatedIds: ['butterfly', 'leaf', 'tree'],
      reaction: 'The petals open a little wider and a tiny visitor flutters into view.',
    ),
    'tree': const DiscoveryPack(
      curiosity: 'A tree is not just one giant object. It is a whole connected system.',
      wowDiscoveries: [
        'Roots, trunk, branches and leaves work together as parts of one living system.',
        'A tree can provide food, shelter or resting places for many other living things.',
        'The pattern in bark can be different from one tree to another, almost like a natural fingerprint.',
      ],
      mysteryClues: [
        'I have roots below the ground.',
        'I can give animals places to live.',
        'My bark has patterns.',
      ],
      whatIfPrompts: [
        'What might you find if you look carefully around the base of a tree?',
      ],
      whatIfChoices: [
        'Tiny insects or fallen leaves',
        'A television',
        'A swimming pool',
      ],
      whatIfAnswer: 'The ground around a tree can become a tiny habitat for insects, fallen leaves and other small life.',
      surpriseIds: ['tree_hidden_hollow', 'bird_reveal', 'tiny_trail'],
      relatedIds: ['leaf', 'bird', 'butterfly'],
      reaction: 'A leaf trembles, then a tiny trail leads around the tree.',
    ),
    'leaf': const DiscoveryPack(
      curiosity: 'A leaf can look flat and quiet, but it is full of tiny structures doing important work.',
      wowDiscoveries: [
        'Leaf veins form a transport network that moves water and other materials through the leaf.',
        'Different plants can have dramatically different leaf shapes and edges.',
        'Leaves can change color when the plant changes how it uses or stores its pigments.',
      ],
      mysteryClues: [
        'I can have a network of veins.',
        'I can change color.',
        'I can have very different shapes.',
      ],
      whatIfPrompts: ['What do you think the tiny lines on a leaf are doing?'],
      whatIfChoices: [
        'Helping move water and materials',
        'Making music',
        'Holding the sky',
      ],
      whatIfAnswer: 'The veins help transport water and other materials through the leaf.',
      surpriseIds: ['leaf_vein_map', 'color_change', 'butterfly_follow'],
      relatedIds: ['tree', 'flower', 'butterfly'],
      reaction: 'The leaf lights up along its veins like a tiny map.',
    ),
    'butterfly': const DiscoveryPack(
      curiosity: 'Those colorful wings are covered with something much tinier than they look.',
      wowDiscoveries: [
        'Butterfly wings are covered with microscopic scales that can create colors and patterns.',
        'A butterfly goes through a complete life-cycle transformation from caterpillar to adult.',
        'Butterflies use a long tube-like proboscis to sip liquids such as nectar.',
      ],
      mysteryClues: [
        'I start life very differently.',
        'My wings have tiny scales.',
        'I often visit flowers.',
      ],
      whatIfPrompts: [
        'What do you think happens before a butterfly has wings?',
      ],
      whatIfChoices: [
        'It is a caterpillar',
        'It is a tiny bird',
        'It is a seed',
      ],
      whatIfAnswer: 'Before becoming a butterfly, it passes through stages including a caterpillar and a chrysalis.',
      surpriseIds: ['butterfly_transform', 'wing_scales', 'flower_follow'],
      relatedIds: ['flower', 'leaf', 'tree'],
      reaction: 'The butterfly flaps once and leaves a trail of glowing wing-shapes behind it.',
    ),
    'bird': const DiscoveryPack(
      curiosity: 'Look at the beak and feathers. They can give clues about how a bird lives.',
      wowDiscoveries: [
        'Bird beaks come in many shapes because different birds use them in different ways.',
        'Feathers are useful for more than flying: they can also help with warmth, display and protection.',
        'Many birds build nests with surprisingly different materials and designs.',
      ],
      mysteryClues: [
        'I have feathers.',
        'My beak has a particular shape.',
        'I may build a nest.',
      ],
      whatIfPrompts: ['Why might different birds have different beaks?'],
      whatIfChoices: [
        'Different beaks help with different jobs',
        'Every bird eats the same food',
        'Beaks are only for decoration',
      ],
      whatIfAnswer: 'Different beak shapes can help birds collect or eat different kinds of food.',
      surpriseIds: ['bird_call', 'nest_reveal', 'feather_zoom'],
      relatedIds: ['tree', 'flower', 'water'],
      reaction:
          'A soft chirp answers Vee and a tiny nest appears in the distance.',
    ),
    'rock': const DiscoveryPack(
      curiosity: 'This rock has a story. Its surface can carry clues about what happened to it over time.',
      wowDiscoveries: [
        'Water, wind and movement can slowly wear rock surfaces down and change their shapes.',
        'Some rocks contain visible or hidden minerals that affect their color and sparkle.',
        'A smooth pebble may have travelled or been rubbed against other surfaces for a very long time.',
      ],
      mysteryClues: [
        'I can be rough or smooth.',
        'I can contain minerals.',
        'My shape can change over a long time.',
      ],
      whatIfPrompts: [
        'What might make a rough rock become smoother over a long time?',
      ],
      whatIfChoices: ['Water and movement', 'A birthday cake', 'A flashlight'],
      whatIfAnswer: 'Moving water, wind and repeated rubbing can gradually wear down rock surfaces.',
      surpriseIds: ['mineral_sparkle', 'rock_time_trail', 'hidden_pattern'],
      relatedIds: ['water', 'tree', 'leaf'],
      reaction: 'A tiny sparkle appears inside the rock, revealing a hidden mineral-like pattern.',
    ),
    'water': const DiscoveryPack(
      curiosity: 'Water is a shape-shifter. Give it a different place and it behaves differently.',
      wowDiscoveries: [
        'Water can become ice or water vapor when its temperature changes.',
        'Liquid water takes the shape of the container holding it.',
        'Water can move through the environment as part of a repeating cycle.',
      ],
      mysteryClues: [
        'I can freeze.',
        'I can flow.',
        'I can become invisible vapor.',
      ],
      whatIfPrompts: [
        'What do you think happens to water when it gets cold enough?',
      ],
      whatIfChoices: [
        'It can freeze into ice',
        'It turns into sand',
        'It becomes a leaf',
      ],
      whatIfAnswer:
          'When water gets cold enough, it can freeze into solid ice.',
      surpriseIds: ['water_shape_shift', 'tiny_rainbow', 'ice_reveal'],
      relatedIds: ['rock', 'leaf', 'flower'],
      reaction:
          'The water ripples, then a tiny rainbow flashes across the scene.',
    ),
    'toothbrush': const DiscoveryPack(
      curiosity: 'A toothbrush looks simple, but its tiny bristles are designed to reach lots of little spaces.',
      wowDiscoveries: [
        'The small bristles help reach around the different surfaces of teeth.',
        'Brushing works by moving the bristles across surfaces rather than simply holding them still.',
        'Toothbrushes are designed with different shapes and bristle arrangements for easier cleaning.',
      ],
      mysteryClues: [
        'I have many tiny bristles.',
        'I have a handle.',
        'I help clean teeth.',
      ],
      whatIfPrompts: [
        'What happens if the bristles move across a surface instead of staying still?',
      ],
      whatIfChoices: [
        'They can help sweep away debris',
        'They grow leaves',
        'They make a balloon',
      ],
      whatIfAnswer: 'Moving bristles can help clean away food particles and plaque from tooth surfaces.',
      surpriseIds: ['bristle_zoom', 'sparkle_teeth', 'bubble_swirl'],
      relatedIds: ['water', 'soap', 'mirror'],
      reaction: 'The bristles zoom in like tiny explorers and reveal a sparkling clean path.',
    ),
    'soap': const DiscoveryPack(
      curiosity: 'Soap and water can team up to do something neither one does quite the same way alone.',
      wowDiscoveries: [
        'Soap molecules can help loosen oily dirt so water can carry it away.',
        'Soap can trap some dirt and oils in tiny structures that mix better with water.',
        'Bubbles are thin films of soapy water wrapped around air.',
      ],
      mysteryClues: [
        'I can make bubbles.',
        'I work with water.',
        'I help clean things.',
      ],
      whatIfPrompts: [
        'Why do you think soap and water make a better cleaning team?',
      ],
      whatIfChoices: [
        'Soap helps loosen oils and dirt',
        'Soap makes dirt heavier',
        'Soap turns water into stone',
      ],
      whatIfAnswer: 'Soap helps loosen oils and dirt so they can be carried away more easily with water.',
      surpriseIds: ['bubble_swirl', 'soap_rainbow', 'tiny_bubble_world'],
      relatedIds: ['water', 'toothbrush', 'mirror'],
      reaction: 'A bubble floats up, grows huge for a moment, and reveals a rainbow sheen.',
    ),
    'mirror': const DiscoveryPack(
      curiosity: 'A mirror does not make a copy. It sends light back to your eyes so you can see a reflection.',
      wowDiscoveries: [
        'A smooth surface can reflect light in an organized way, creating a clear image.',
        'Changing the angle between you and a mirror changes what you can see in it.',
        'You can use reflections to notice things that are not directly in front of you.',
      ],
      mysteryClues: [
        'I reflect light.',
        'I have a smooth surface.',
        'I can show something behind you.',
      ],
      whatIfPrompts: ['What changes when you move to the side of a mirror?'],
      whatIfChoices: [
        'The view in the reflection changes',
        'The mirror melts',
        'The room becomes invisible',
      ],
      whatIfAnswer: 'Moving changes the angles of the light reaching your eyes, so the reflected view changes too.',
      surpriseIds: ['mirror_message', 'reflection_twist', 'vee_wink'],
      relatedIds: ['lamp', 'water', 'toothbrush'],
      reaction: 'Vee waves at the reflection… and the reflection waves back with a tiny sparkle.',
    ),
    'book': const DiscoveryPack(
      curiosity: 'A book can hide a whole world without making a sound.',
      wowDiscoveries: [
        'Pictures, symbols and words can let your brain build scenes that are not physically in the room.',
        'Turning pages changes the order in which a story unfolds.',
        'Different books use different combinations of pictures, words, diagrams and symbols to communicate ideas.',
      ],
      mysteryClues: [
        'I have pages.',
        'I can tell a story.',
        'I can carry information without speaking.',
      ],
      whatIfPrompts: [
        'What happens to a story if you change the order of its pages?',
      ],
      whatIfChoices: [
        'The story can become mixed up',
        'The book becomes a sandwich',
        'Nothing can ever change',
      ],
      whatIfAnswer: 'Changing the order can change the sequence and meaning of the story.',
      surpriseIds: ['secret_shelf', 'page_portal', 'story_star'],
      relatedIds: ['lamp', 'toy', 'mirror'],
      reaction: 'One page glows and a tiny story-world peeks out from between the pages.',
    ),
    'lamp': const DiscoveryPack(
      curiosity: 'A lamp turns something you cannot see into something your eyes can notice: light.',
      wowDiscoveries: [
        'A lamp changes electrical energy into light and also releases some energy as heat.',
        'Changing the direction of light can change which parts of a room are easy to see.',
        'Shadows appear when an object blocks light from reaching a surface.',
      ],
      mysteryClues: [
        'I help you see.',
        'I can make a shadow appear.',
        'I can be switched on and off.',
      ],
      whatIfPrompts: ['What happens to a shadow when a light moves?'],
      whatIfChoices: [
        'The shadow can move or change size',
        'The shadow becomes a balloon',
        'The light stops existing',
      ],
      whatIfAnswer: 'Moving the light changes the angles, so the shadow can move or change its size and direction.',
      surpriseIds: ['shadow_puppet', 'light_beam', 'hidden_shape'],
      relatedIds: ['mirror', 'book', 'water'],
      reaction: 'The lamp clicks on and Vee discovers a secret shadow shape on the wall.',
    ),
    'balloon': const DiscoveryPack(
      curiosity: 'A balloon can push against the air around it and even carry a lighter-than-air gas upward.',
      wowDiscoveries: [
        'A stretched balloon stores energy in its rubber and can release it when air rushes out.',
        'A balloon filled with helium can rise because helium is less dense than the surrounding air.',
        'Air takes up space even though we cannot see it directly.',
      ],
      mysteryClues: [
        'I stretch when filled.',
        'I contain air or another gas.',
        'I can move when air pushes or escapes.',
      ],
      whatIfPrompts: [
        'What do you think happens when air escapes quickly from a balloon?',
      ],
      whatIfChoices: [
        'The balloon can zoom around',
        'It grows into a tree',
        'It becomes a rock',
      ],
      whatIfAnswer: 'Fast-moving escaping air can push the balloon in the opposite direction.',
      surpriseIds: ['balloon_zoom', 'balloon_pop_safe', 'air_trail'],
      relatedIds: ['water', 'mirror', 'toy'],
      reaction: 'The balloon wobbles, zooms a tiny distance, and leaves a curly air trail.',
    ),
    'plate': const DiscoveryPack(
      curiosity:
          'A plate is simple, but its shape makes it surprisingly useful.',
      wowDiscoveries: [
        'A broad, shallow surface makes it easier to keep food together while eating.',
        'A raised rim can help keep liquids and food from sliding away.',
        'Plate shapes can be designed around how food is served and used.',
      ],
      mysteryClues: [
        'I can be round.',
        'I hold food.',
        'I have a broad surface.',
      ],
      whatIfPrompts: ['Why might a plate have a raised edge?'],
      whatIfChoices: [
        'To help keep food from sliding off',
        'To make it fly',
        'To hide a book',
      ],
      whatIfAnswer: 'A raised edge can help keep food and some liquids contained on the plate.',
      surpriseIds: ['plate_pattern', 'food_sort', 'table_transform'],
      relatedIds: ['cup', 'apple', 'banana'],
      reaction:
          'The plate spins gently and reveals a hidden pattern around its rim.',
    ),
    'cup': const DiscoveryPack(
      curiosity:
          'A cup is useful because its empty space is part of its design.',
      wowDiscoveries: [
        'The hollow space inside a cup is what lets it hold a drink.',
        'A handle can make a cup easier to hold without touching the hottest part.',
        'The same basic cup idea can be made from many materials and shapes.',
      ],
      mysteryClues: [
        'I have an empty space inside.',
        'I can hold a drink.',
        'Some cups have handles.',
      ],
      whatIfPrompts: ['What would happen if a cup had no hollow space inside?'],
      whatIfChoices: [
        'It could not hold a drink',
        'It would become a balloon',
        'It would grow roots',
      ],
      whatIfAnswer: 'Without the hollow space, there would be nowhere for the drink to sit.',
      surpriseIds: ['cup_fill', 'water_ripple', 'handle_secret'],
      relatedIds: ['water', 'plate', 'apple'],
      reaction: 'A tiny ripple appears inside the cup and turns into a glowing swirl.',
    ),
    'toy': const DiscoveryPack(
      curiosity: 'A toy can become almost anything when imagination changes the story around it.',
      wowDiscoveries: [
        'Pretend play lets children use objects in new roles and build stories around them.',
        'Sorting toys by color, shape or size is a way of comparing properties.',
        'Some toys are deliberately designed to encourage movement, building or problem-solving.',
      ],
      mysteryClues: [
        'I can be used for pretend play.',
        'I can have many shapes.',
        'I can become part of a story.',
      ],
      whatIfPrompts: [
        'What if the same toy became a spaceship instead of a car?',
      ],
      whatIfChoices: [
        'The story changes',
        'The toy disappears',
        'The room turns into water',
      ],
      whatIfAnswer: 'Changing the pretend role changes the story while the physical toy stays the same.',
      surpriseIds: ['toy_portal', 'toy_story_shift', 'hidden_button'],
      relatedIds: ['book', 'balloon', 'lamp'],
      reaction: 'The toy gets a tiny sparkle and suddenly becomes part of Vee’s adventure story.',
    ),
  };

  static DiscoveryPack forItem(CatalogItem item) =>
      _packs[item.id] ?? _fallback(item);

  static DiscoveryPack _fallback(CatalogItem item) => DiscoveryPack(
    curiosity:
        'Look closely at ${item.name}. There may be more to it than you notice at first.',
    wowDiscoveries: item.facts.map((f) => f.text).toList(),
    mysteryClues: item.tags.take(3).map((t) => 'I can be $t.').toList(),
    whatIfPrompts: [
      'What do you think you would notice if you looked at it very closely?',
    ],
    whatIfChoices: const ['A hidden detail', 'Nothing new', 'A tiny surprise'],
    whatIfAnswer:
        'Careful observation can reveal details you might miss at first.',
    surpriseIds: const ['small_glow', 'tiny_trail', 'hidden_shape'],
    relatedIds: const [],
    reaction: 'A tiny magical detail appears.',
  );

  static SurpriseEvent event(
    String id, {
    EnvironmentMode mode = EnvironmentMode.outdoor,
  }) {
    const all = <String, SurpriseEvent>{
      'small_glow': SurpriseEvent(
        'small_glow',
        'Tiny Mystery',
        'A little glow appears nearby. What could it be?',
        '✨',
      ),
      'leaf_vein_map': SurpriseEvent(
        'leaf_vein_map',
        'Leaf Map',
        'The tiny transport lines in the leaf light up like a map.',
        '🍃',
      ),
      'tiny_trail': SurpriseEvent(
        'tiny_trail',
        'Follow Me!',
        'A tiny trail has appeared. It may lead to another discovery.',
        '👣',
      ),
      'hidden_shape': SurpriseEvent(
        'hidden_shape',
        'Look Closer!',
        'A hidden shape appears when you look carefully.',
        '🔍',
      ),
      'butterfly_follow': SurpriseEvent(
        'butterfly_follow',
        'Flutter Trail',
        'A butterfly flutters past and leaves a sparkling trail.',
        '🦋',
      ),
      'flower_bloom': SurpriseEvent(
        'flower_bloom',
        'Secret Bloom',
        'A closed flower suddenly opens.',
        '🌸',
      ),
      'flower_follow': SurpriseEvent(
        'flower_follow',
        'Follow the Flower',
        'A flower points Vee toward the next little discovery.',
        '🌸',
      ),
      'garden_bloom': SurpriseEvent(
        'garden_bloom',
        'Garden Glow',
        'A tiny patch of the world wakes up with color.',
        '🌱',
      ),
      'hidden_pollen': SurpriseEvent(
        'hidden_pollen',
        'Golden Dust',
        'Tiny golden pollen dots shimmer in the air.',
        '✨',
      ),
      'butterfly_transform': SurpriseEvent(
        'butterfly_transform',
        'A Big Change',
        'Vee discovers the butterfly’s amazing transformation story.',
        '🐛',
      ),
      'wing_scales': SurpriseEvent(
        'wing_scales',
        'Wing Zoom!',
        'The wing pattern zooms in to reveal tiny scales.',
        '🔬',
      ),
      'bird_call': SurpriseEvent(
        'bird_call',
        'Hello Up There!',
        'A little bird call answers Vee from nearby.',
        '🐦',
      ),
      'bird_reveal': SurpriseEvent(
        'bird_reveal',
        'Feathered Secret',
        'A bird hops into view and reveals the next clue.',
        '🐦',
      ),
      'nest_reveal': SurpriseEvent(
        'nest_reveal',
        'Hidden Nest',
        'A tiny nest peeks out from the leaves.',
        '🪺',
      ),
      'feather_zoom': SurpriseEvent(
        'feather_zoom',
        'Feather Close-Up',
        'One feather reveals a surprising pattern.',
        '🪶',
      ),
      'mineral_sparkle': SurpriseEvent(
        'mineral_sparkle',
        'Secret Sparkle',
        'A hidden sparkle appears inside the rock.',
        '💎',
      ),
      'rock_time_trail': SurpriseEvent(
        'rock_time_trail',
        'Time Trail',
        'Vee imagines the long journey that shaped the rock.',
        '🪨',
      ),
      'hidden_pattern': SurpriseEvent(
        'hidden_pattern',
        'Pattern Found',
        'A pattern appears when Vee turns the object around.',
        '🔷',
      ),
      'water_shape_shift': SurpriseEvent(
        'water_shape_shift',
        'Shape Shifter',
        'The water changes shape to match its container.',
        '💧',
      ),
      'tiny_rainbow': SurpriseEvent(
        'tiny_rainbow',
        'Mini Rainbow',
        'A little rainbow flashes across the water.',
        '🌈',
      ),
      'ice_reveal': SurpriseEvent(
        'ice_reveal',
        'Cold Surprise',
        'A few sparkling ice crystals appear.',
        '🧊',
      ),
      'bristle_zoom': SurpriseEvent(
        'bristle_zoom',
        'Tiny Explorers',
        'The toothbrush bristles become a giant little landscape.',
        '🪥',
      ),
      'sparkle_teeth': SurpriseEvent(
        'sparkle_teeth',
        'Sparkle Path',
        'A clean path sparkles like a tiny trail.',
        '✨',
      ),
      'bubble_swirl': SurpriseEvent(
        'bubble_swirl',
        'Bubble World',
        'A giant bubble floats up and shows a rainbow sheen.',
        '🫧',
      ),
      'soap_rainbow': SurpriseEvent(
        'soap_rainbow',
        'Rainbow Bubble',
        'Light dances across a soap bubble.',
        '🌈',
      ),
      'tiny_bubble_world': SurpriseEvent(
        'tiny_bubble_world',
        'Bubble City',
        'Tiny bubbles gather into a funny little bubble world.',
        '🫧',
      ),
      'mirror_message': SurpriseEvent(
        'mirror_message',
        'Mirror Mystery',
        'A friendly sparkle writes a tiny message in the reflection.',
        '🪞',
      ),
      'reflection_twist': SurpriseEvent(
        'reflection_twist',
        'Angle Trick',
        'Move around and watch the reflection change.',
        '🔄',
      ),
      'vee_wink': SurpriseEvent(
        'vee_wink',
        'Wait…',
        'Vee’s reflection seems to wink first!',
        '😉',
      ),
      'secret_shelf': SurpriseEvent(
        'secret_shelf',
        'Secret Shelf',
        'One book slides aside and reveals a hidden shelf.',
        '📚',
      ),
      'page_portal': SurpriseEvent(
        'page_portal',
        'Page Portal',
        'A glowing page looks like a tiny doorway into the story.',
        '🚪',
      ),
      'story_star': SurpriseEvent(
        'story_star',
        'Story Star',
        'A tiny star appears between two pages.',
        '⭐',
      ),
      'shadow_puppet': SurpriseEvent(
        'shadow_puppet',
        'Shadow Surprise',
        'The light makes a funny shape on the wall.',
        '👋',
      ),
      'light_beam': SurpriseEvent(
        'light_beam',
        'Light Path',
        'A beam of light reveals something Vee missed.',
        '💡',
      ),
      'balloon_zoom': SurpriseEvent(
        'balloon_zoom',
        'Zoom!',
        'The balloon wiggles away and Vee follows its path.',
        '🎈',
      ),
      'balloon_pop_safe': SurpriseEvent(
        'balloon_pop_safe',
        'Pop Surprise',
        'Pop! Confetti appears instead of a scary sound.',
        '🎉',
      ),
      'air_trail': SurpriseEvent(
        'air_trail',
        'Invisible Air',
        'A curly trail shows where the moving air went.',
        '💨',
      ),
      'plate_pattern': SurpriseEvent(
        'plate_pattern',
        'Hidden Rim',
        'A pattern appears around the plate’s edge.',
        '🍽️',
      ),
      'food_sort': SurpriseEvent(
        'food_sort',
        'Sorting Magic',
        'The table lights up as matching objects find each other.',
        '✨',
      ),
      'table_transform': SurpriseEvent(
        'table_transform',
        'Table Transform',
        'The table becomes a tiny adventure map.',
        '🗺️',
      ),
      'cup_fill': SurpriseEvent(
        'cup_fill',
        'Ripple!',
        'A tiny ripple dances inside the cup.',
        '🥤',
      ),
      'water_ripple': SurpriseEvent(
        'water_ripple',
        'Ripple Trail',
        'The ripple points toward another discovery.',
        '💧',
      ),
      'handle_secret': SurpriseEvent(
        'handle_secret',
        'Handle Helper',
        'The handle lights up and shows why it is useful.',
        '🥤',
      ),
      'toy_portal': SurpriseEvent(
        'toy_portal',
        'Pretend Portal',
        'The toy becomes the hero of a tiny pretend world.',
        '🧸',
      ),
      'toy_story_shift': SurpriseEvent(
        'toy_story_shift',
        'Story Switch',
        'The same toy suddenly has a brand-new adventure role.',
        '🚀',
      ),
      'hidden_button': SurpriseEvent(
        'hidden_button',
        'Secret Button',
        'A tiny button appears. Tap it to see what happens.',
        '🔘',
      ),
      'apple_star_cut': SurpriseEvent(
        'apple_star_cut',
        'Seed Star',
        'The inside of the apple reveals a tiny star pattern.',
        '⭐',
      ),
      'apple_seed_secret': SurpriseEvent(
        'apple_seed_secret',
        'Seed Secret',
        'The seeds become the beginning of a new plant story.',
        '🌱',
      ),
      'banana_bunch': SurpriseEvent(
        'banana_bunch',
        'Banana Bunch',
        'Vee discovers that one banana can be part of a much bigger bunch.',
        '🍌',
      ),
      'banana_color_shift': SurpriseEvent(
        'banana_color_shift',
        'Color Clue',
        'The peel changes color to show a ripening clue.',
        '🟡',
      ),
      'hidden_seed_trail': SurpriseEvent(
        'hidden_seed_trail',
        'Tiny Beginning',
        'A tiny seed trail appears near the fruit.',
        '🌱',
      ),
      'tomato_seed_map': SurpriseEvent(
        'tomato_seed_map',
        'Seed Map',
        'The inside reveals a tiny map of seed chambers.',
        '🍅',
      ),
      'color_shift': SurpriseEvent(
        'color_shift',
        'Color Change',
        'A color clue shifts before Vee’s eyes.',
        '🎨',
      ),
      'color_change': SurpriseEvent(
        'color_change',
        'Color Clue',
        'The color gives Vee one more clue to follow.',
        '🎨',
      ),
      'carrot_underground': SurpriseEvent(
        'carrot_underground',
        'Under the Soil',
        'A peek below the ground reveals the hidden root.',
        '🥕',
      ),
      'hidden_root': SurpriseEvent(
        'hidden_root',
        'Secret Root',
        'Vee discovers the part of the plant that was hiding underground.',
        '🌱',
      ),
      'garden_tunnel': SurpriseEvent(
        'garden_tunnel',
        'Tiny Tunnel',
        'A tiny tunnel appears under the garden soil.',
        '🕳️',
      ),
      'tree_hidden_hollow': SurpriseEvent(
        'tree_hidden_hollow',
        'Tree Secret',
        'A small hollow becomes visible in the trunk.',
        '🌳',
      ),
    };
    return all[id] ?? all['small_glow']!;
  }

  static SurpriseEvent randomEvent(
    List<String> ids, {
    Random? random,
    EnvironmentMode mode = EnvironmentMode.outdoor,
  }) {
    final r = random ?? Random();
    if (ids.isEmpty) return event('small_glow', mode: mode);
    return event(ids[r.nextInt(ids.length)], mode: mode);
  }
}
