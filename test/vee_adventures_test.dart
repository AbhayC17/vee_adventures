import 'package:flutter_test/flutter_test.dart';
import 'package:vees_adventures/services/activity_selection/activity_selector.dart';
import 'package:vees_adventures/services/history/game_history.dart';
import 'package:vees_adventures/services/safety/safety_validator.dart';
import 'package:vees_adventures/models/activity.dart';
import 'package:vees_adventures/models/content_catalog.dart';
import 'package:vees_adventures/models/environment_mode.dart';
import 'package:vees_adventures/services/discovery_engine.dart';

void main(){
  test('activity selector avoids immediate repetition',(){final h=GameHistory();final s=ActivitySelector();final next=s.select(age:4,
  progression:1,lastActivity:'spot',history:h,movementPreference:'Hop & reach', environmentMode: EnvironmentMode.outdoor);expect(next,
  isNot(ActivityType.spot));});
  test('movement profile drives activity preference',(){
    final h=GameHistory();
    final s=ActivitySelector();
    expect(s.select(age:4,progression:1,lastActivity:'',history:h,movementPreference:'Hop & reach', environmentMode: EnvironmentMode.outdoor),
    ActivityType.play);
    expect(s.select(age:4,progression:1,lastActivity:'',history:h,movementPreference:'Balance & stretch',
      environmentMode: EnvironmentMode.indoor),
    ActivityType.explore);
  });
  test('safety blocks banned content',(){final s=SafetyValidator();expect(s.validate({'activityType':'play',
  'movementSequence':[{'name':'jump','count':3}],'text':'walk near a road'}),isFalse);});
  test('fact memory cycles through all facts before repeating',(){
    final item=ContentCatalog.get('apple')!;
    final memory=FactMemory();
    final facts=List.generate(4,(_)=>memory.nextFact(item));
    expect(facts.toSet().length,4);
    expect(memory.nextFact(item), isNotEmpty);
  });
  test('settings expose reusable catalog items',(){
    for(final setting in ContentCatalog.settings){
      expect(setting.itemIds, isNotEmpty);
      expect(ContentCatalog.forSetting(setting.id), isNotEmpty);
    }
  });
  test('environment mode exposes separate regular and special worlds',(){
    expect(ContentCatalog.settingsForMode(EnvironmentMode.indoor).every((s)=>!s.isSpecialEvent),isTrue);
    expect(ContentCatalog.settingsForMode(EnvironmentMode.outdoor).every((s)=>!s.isSpecialEvent),isTrue);
    expect(ContentCatalog.specialEventsForMode(EnvironmentMode.indoor).isNotEmpty,isTrue);
    expect(ContentCatalog.specialEventsForMode(EnvironmentMode.outdoor).isNotEmpty,isTrue);
  });

  test('discovery packs provide more than generic facts',(){
    final item = ContentCatalog.get('butterfly')!;
    final pack = DiscoveryEngine.forItem(item);
    expect(pack.wowDiscoveries.length, greaterThanOrEqualTo(3));
    expect(pack.mysteryClues.length, greaterThanOrEqualTo(2));
    expect(pack.whatIfChoices.length, greaterThanOrEqualTo(2));
    expect(pack.surpriseIds, isNotEmpty);
  });
  test('discovery surprise IDs resolve to real events',(){
    for(final item in ContentCatalog.items){
      final pack = DiscoveryEngine.forItem(item);
      for(final id in pack.surpriseIds){
        expect(DiscoveryEngine.event(id).id, id);
      }
    }
  });
  test('safety accepts engine-approved movement', () {
    final s = SafetyValidator();
    expect(
      s.validate({
        'activityType': 'play',
        'movementSequence': [
          {'name': 'jump', 'count': 3},
          {'name': 'clap', 'count': 2},
        ],
      }),
      isTrue,
    );
  });
}
