angular.module('beamng.apps')
.directive('steerCam', [function () {
  return {
    template: [
      '<div class="steerCamApp">',
        '<style>',
          '.steerCamApp{font-family:"Segoe UI",sans-serif;color:#e8e8ea;background:rgba(18,18,20,0.88);',
            'border-radius:7px;padding:9px 11px;box-sizing:border-box;width:100%;height:100%;overflow:auto;font-size:12px}',
          '.steerCamApp .sc-title{font-weight:700;font-size:14px;letter-spacing:.5px;margin-bottom:6px;color:#ff7a18}',
          '.steerCamApp .sc-presets{display:flex;gap:5px;margin-bottom:8px}',
          '.steerCamApp .sc-presets button{flex:1 1 0;background:rgba(255,255,255,0.08);color:#e8e8ea;border:1px solid rgba(255,255,255,0.14);',
            'border-radius:4px;padding:4px 6px;font-size:11px;cursor:pointer}',
          '.steerCamApp .sc-presets button:hover{background:rgba(255,255,255,0.16)}',
          '.steerCamApp .sc-presets button.active{background:#ff7a18;border-color:#ff7a18;color:#161616;font-weight:700}',
          '.steerCamApp .sc-glance-btns{display:flex;gap:5px;margin:7px 0 2px}',
          '.steerCamApp .sc-glance-btns button{flex:1 1 0;background:rgba(255,255,255,0.08);color:#e8e8ea;',
            'border:1px solid rgba(255,255,255,0.14);border-radius:4px;padding:5px 6px;font-size:11px;cursor:pointer}',
          '.steerCamApp .sc-glance-btns button:hover{background:rgba(255,255,255,0.16)}',
          '.steerCamApp .sc-glance-btns button.active{background:#ff7a18;border-color:#ff7a18;color:#161616;font-weight:700}',
          '.steerCamApp .sc-sec{font-weight:600;margin:4px 0 5px;color:#ffae6b;',
            'border-bottom:1px solid rgba(255,255,255,0.12);padding-bottom:2px}',
          '.steerCamApp .sc-row{display:flex;align-items:center;gap:7px;margin:5px 0}',
          '.steerCamApp .sc-row>span{flex:0 0 84px}',
          '.steerCamApp .sc-row input[type=range]{flex:1 1 auto;min-width:34px;accent-color:#ff7a18}',
          '.steerCamApp .sc-row>b{flex:0 0 42px;text-align:right;color:#fff;font-variant-numeric:tabular-nums}',
          '.steerCamApp .sc-chk label{display:flex;align-items:center;gap:7px;cursor:pointer}',
          '.steerCamApp .sc-chk input{accent-color:#ff7a18}',
          '.steerCamApp.locked .sc-row{opacity:0.5}',
          '.steerCamApp.locked .sc-chk label{cursor:default}',
          '.steerCamApp .sc-row.sc-dim{opacity:0.45}',
          '.steerCamApp .sc-sec .sc-en{display:flex;align-items:center;gap:7px;cursor:pointer}',
          '.steerCamApp .sc-sec .sc-en input{accent-color:#ff7a18}',
          '.steerCamApp .sc-hint{font-size:10px;color:#9a9aa0;margin-top:6px}',
        '</style>',

        '<div class="sc-title">SteerCam</div>',

        '<div class="sc-presets">',
          '<button ng-repeat="p in presetNames" ng-class="{active: preset===p}" ng-click="choose(p)">{{p}}</button>',
        '</div>',

        '<div class="sc-sec"><label class="sc-en"><input type="checkbox" ng-model="cfg.steerEnable" ng-change="set(\'steerEnable\', cfg.steerEnable)" ng-disabled="locked"> Steer camera turn</label></div>',
        '<div class="sc-row" ng-show="cfg.steerEnable"><span>Angle</span>',
          '<input type="range" min="0" max="90" step="1" ng-model="cfg.angle" ng-change="set(\'angle\', cfg.angle)" ng-disabled="locked">',
          '<b>{{cfg.angle}}°</b></div>',
        '<div class="sc-row" ng-show="cfg.steerEnable"><span>Steering range</span>',
          '<input type="range" min="10" max="100" step="5" ng-model="cfg.reach" ng-change="set(\'reach\', cfg.reach)" ng-disabled="locked">',
          '<b>{{cfg.reach}}%</b></div>',
        '<div class="sc-row" ng-show="cfg.steerEnable"><span>Stiffness</span>',
          '<input type="range" min="1" max="40" step="1" ng-model="cfg.stiffness" ng-change="set(\'stiffness\', cfg.stiffness)" ng-disabled="locked">',
          '<b>{{cfg.stiffness}}</b></div>',
        '<div class="sc-row sc-chk" ng-show="cfg.steerEnable"><label><input type="checkbox" ng-model="cfg.speedFade" ng-change="set(\'speedFade\', cfg.speedFade)" ng-disabled="locked"> Fade in with speed</label></div>',
        '<div class="sc-row" ng-show="cfg.steerEnable && cfg.speedFade"><span>Fade speed</span>',
          '<input type="range" min="0.5" max="40" step="0.5" ng-model="cfg.fadeSpeed" ng-change="set(\'fadeSpeed\', cfg.fadeSpeed)" ng-disabled="locked">',
          '<b>{{cfg.fadeSpeed}}</b></div>',

        '<div class="sc-sec"><label class="sc-en"><input type="checkbox" ng-model="cfg.glanceEnable" ng-change="set(\'glanceEnable\', cfg.glanceEnable)" ng-disabled="locked"> Blind-spot glance</label></div>',
        '<div class="sc-row" ng-show="cfg.glanceEnable"><span>Left angle</span>',
          '<input type="range" min="0" max="170" step="5" ng-model="cfg.glanceLeft" ng-change="set(\'glanceLeft\', cfg.glanceLeft)" ng-disabled="locked">',
          '<b>{{cfg.glanceLeft}}°</b></div>',
        '<div class="sc-row" ng-show="cfg.glanceEnable"><span>Right angle</span>',
          '<input type="range" min="0" max="170" step="5" ng-model="cfg.glanceRight" ng-change="set(\'glanceRight\', cfg.glanceRight)" ng-disabled="locked">',
          '<b>{{cfg.glanceRight}}°</b></div>',
        '<div class="sc-row" ng-show="cfg.glanceEnable"><span>Glance time</span>',
          '<input type="range" min="0" max="500" step="10" ng-model="cfg.glanceTime" ng-change="set(\'glanceTime\', cfg.glanceTime)" ng-disabled="locked">',
          '<b>{{cfg.glanceTime}}ms</b></div>',
        '<div class="sc-row" ng-show="cfg.glanceEnable"><span>Left offset</span>',
          '<input type="range" min="0" max="0.6" step="0.01" ng-model="cfg.glanceOffsetLeft" ng-change="set(\'glanceOffsetLeft\', cfg.glanceOffsetLeft)" ng-disabled="locked">',
          '<b>{{cfg.glanceOffsetLeft}}m</b></div>',
        '<div class="sc-row" ng-show="cfg.glanceEnable"><span>Right offset</span>',
          '<input type="range" min="0" max="0.6" step="0.01" ng-model="cfg.glanceOffsetRight" ng-change="set(\'glanceOffsetRight\', cfg.glanceOffsetRight)" ng-disabled="locked">',
          '<b>{{cfg.glanceOffsetRight}}m</b></div>',
        '<div class="sc-glance-btns" ng-show="cfg.glanceEnable">',
          '<button ng-class="{active: glanceSide===\'left\'}" ng-click="toggleGlance(\'left\')">Preview left</button>',
          '<button ng-class="{active: glanceSide===\'right\'}" ng-click="toggleGlance(\'right\')">Preview right</button>',
        '</div>',
        '<div class="sc-hint" ng-show="cfg.glanceEnable">Preview holds the glance so you can tune the angle. Needs the SteerCam view active (press C).</div>',

        '<div class="sc-sec"><label class="sc-en"><input type="checkbox" ng-model="cfg.speedModEnable" ng-change="set(\'speedModEnable\', cfg.speedModEnable)" ng-disabled="locked"> Speed modifiers</label></div>',
        '<div class="sc-row sc-chk" ng-class="{\'sc-dim\': !cfg.speedModEnable}"><label><input type="checkbox" ng-model="cfg.vertigo" ng-change="set(\'vertigo\', cfg.vertigo)" ng-disabled="locked || !cfg.speedModEnable"> Speed vertigo (FOV)</label></div>',
        '<div class="sc-row" ng-class="{\'sc-dim\': !cfg.speedModEnable || !cfg.vertigo}"><span>FOV change</span>',
          '<input type="range" min="0" max="40" step="1" ng-model="cfg.vertigoFov" ng-change="set(\'vertigoFov\', cfg.vertigoFov)" ng-disabled="locked || !cfg.speedModEnable || !cfg.vertigo">',
          '<b>{{cfg.vertigoFov}}°</b></div>',
        '<div class="sc-row" ng-class="{\'sc-dim\': !cfg.speedModEnable || !cfg.vertigo}"><span>Dolly depth</span>',
          '<input type="range" min="0" max="6" step="0.1" ng-model="cfg.vertigoDolly" ng-change="set(\'vertigoDolly\', cfg.vertigoDolly)" ng-disabled="locked || !cfg.speedModEnable || !cfg.vertigo">',
          '<b>{{cfg.vertigoDolly}}m</b></div>',
        '<div class="sc-row sc-chk" ng-class="{\'sc-dim\': !cfg.speedModEnable}"><label><input type="checkbox" ng-model="cfg.speedRoll" ng-change="set(\'speedRoll\', cfg.speedRoll)" ng-disabled="locked || !cfg.speedModEnable"> Speed camera roll</label></div>',
        '<div class="sc-row" ng-class="{\'sc-dim\': !cfg.speedModEnable || !cfg.speedRoll}"><span>Roll change</span>',
          '<input type="range" min="0" max="20" step="0.5" ng-model="cfg.rollAngle" ng-change="set(\'rollAngle\', cfg.rollAngle)" ng-disabled="locked || !cfg.speedModEnable || !cfg.speedRoll">',
          '<b>{{cfg.rollAngle}}°</b></div>',
        '<div class="sc-row" ng-class="{\'sc-dim\': !cfg.speedModEnable}"><span>Speed range</span>',
          '<input type="range" min="20" max="400" step="5" ng-model="cfg.speedRange" ng-change="set(\'speedRange\', cfg.speedRange)" ng-disabled="locked || !cfg.speedModEnable">',
          '<b>{{cfg.speedRange}}</b></div>',

        '<div class="sc-hint" ng-show="locked">Default is locked. Switch to Custom to edit.</div>',
      '</div>'
    ].join(''),
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      scope.presetNames = ['Default', 'Custom'];
      scope.preset = 'Default';
      scope.locked = true;
      scope.glanceSide = 'none';
      scope.cfg = {
        steerEnable: true,
        angle: 18, reach: 35, stiffness: 15, speedFade: false, fadeSpeed: 8,
        glanceEnable: true,
        glanceLeft: 115, glanceRight: 115, glanceTime: 120,
        glanceOffsetLeft: 0.10, glanceOffsetRight: 0.10,
        speedModEnable: true,
        vertigo: false, vertigoFov: 15, vertigoDolly: 1.5, speedRoll: false, rollAngle: 5, speedRange: 160
      };

      function pushOne(key, val) {
        if (typeof val === 'boolean') {
          bngApi.engineLua("if steerCam then steerCam.set('" + key + "', " + (val ? 'true' : 'false') + ") end");
        } else {
          var n = parseFloat(val);
          if (isNaN(n)) { return; }
          bngApi.engineLua("if steerCam then steerCam.set('" + key + "', " + n + ") end");
        }
      }

      function syncGlance() {
        bngApi.engineLua('steerCam and steerCam.getGlanceState() or nil', function (st) {
          if (st && typeof st === 'object') {
            scope.$evalAsync(function () {
              var t = st.toggle;
              scope.glanceSide = (t === 1) ? 'left' : (t === -1) ? 'right' : 'none';
            });
          }
        });
      }

      function load() {
        bngApi.engineLua('steerCam and steerCam.getCfg() or nil', function (cfg) {
          if (cfg && typeof cfg === 'object') {
            scope.$evalAsync(function () {
              for (var k in cfg) {
                if (scope.cfg.hasOwnProperty(k)) { scope.cfg[k] = cfg[k]; }
              }
              if (cfg.preset) { scope.preset = cfg.preset; }
              scope.locked = (scope.preset !== 'Custom');
            });
          }
        });
        syncGlance();
      }

      // click Default / Custom
      scope.choose = function (name) {
        bngApi.engineLua("if steerCam then steerCam.setPreset('" + name + "') end");
        scope.preset = name;
        scope.locked = (name !== 'Custom');
        load(); // refresh the shown values for the selected profile
      };

      // edit a slider/checkbox (only possible while on Custom)
      scope.set = function (key, val) {
        if (scope.locked) { return; }
        pushOne(key, val);
      };

      // preview buttons: latch the glance for a side so the angle can be tuned
      // live. Works on either profile (no lock), unlike the sliders.
      scope.toggleGlance = function (side) {
        scope.glanceSide = (scope.glanceSide === side) ? 'none' : side;
        var on = (scope.glanceSide === side);
        bngApi.engineLua("if steerCam then steerCam.glanceSet('" + side + "', " + (on ? 'true' : 'false') + ") end");
      };

      element.ready(function () {
        load();
        setTimeout(load, 600);
      });
    }
  };
}]);
