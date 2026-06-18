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
          '.steerCamApp .sc-hint{font-size:10px;color:#9a9aa0;margin-top:6px}',
        '</style>',

        '<div class="sc-title">SteerCam</div>',

        '<div class="sc-presets">',
          '<button ng-repeat="p in presetNames" ng-class="{active: preset===p}" ng-click="choose(p)">{{p}}</button>',
        '</div>',

        '<div class="sc-sec">Steer camera turn</div>',
        '<div class="sc-row"><span>Angle</span>',
          '<input type="range" min="0" max="90" step="1" ng-model="cfg.angle" ng-change="set(\'angle\', cfg.angle)" ng-disabled="locked">',
          '<b>{{cfg.angle}}\u00B0</b></div>',
        '<div class="sc-row"><span>Full angle at</span>',
          '<input type="range" min="10" max="100" step="5" ng-model="cfg.reach" ng-change="set(\'reach\', cfg.reach)" ng-disabled="locked">',
          '<b>{{cfg.reach}}%</b></div>',
        '<div class="sc-row"><span>Stiffness</span>',
          '<input type="range" min="1" max="40" step="1" ng-model="cfg.stiffness" ng-change="set(\'stiffness\', cfg.stiffness)" ng-disabled="locked">',
          '<b>{{cfg.stiffness}}</b></div>',
        '<div class="sc-row sc-chk"><label><input type="checkbox" ng-model="cfg.invert" ng-change="set(\'invert\', cfg.invert)" ng-disabled="locked"> Invert direction</label></div>',
        '<div class="sc-row sc-chk"><label><input type="checkbox" ng-model="cfg.speedFade" ng-change="set(\'speedFade\', cfg.speedFade)" ng-disabled="locked"> Fade in with speed</label></div>',
        '<div class="sc-row" ng-show="cfg.speedFade"><span>Fade speed</span>',
          '<input type="range" min="0.5" max="40" step="0.5" ng-model="cfg.fadeSpeed" ng-change="set(\'fadeSpeed\', cfg.fadeSpeed)" ng-disabled="locked">',
          '<b>{{cfg.fadeSpeed}}</b></div>',

        '<div class="sc-hint" ng-show="locked">Default is locked. Switch to Custom to edit.</div>',
      '</div>'
    ].join(''),
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      scope.presetNames = ['Default', 'Custom'];
      scope.preset = 'Default';
      scope.locked = true;
      scope.cfg = { angle: 18, reach: 35, stiffness: 15, invert: false, speedFade: false, fadeSpeed: 8 };

      function pushOne(key, val) {
        if (typeof val === 'boolean') {
          bngApi.engineLua("if steerCam then steerCam.set('" + key + "', " + (val ? 'true' : 'false') + ") end");
        } else {
          var n = parseFloat(val);
          if (isNaN(n)) { return; }
          bngApi.engineLua("if steerCam then steerCam.set('" + key + "', " + n + ") end");
        }
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

      element.ready(function () {
        load();
        setTimeout(load, 600);
      });
    }
  };
}]);
