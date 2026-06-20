angular.module('beamng.apps')
.directive('steerCam', [function () {
  return {
    template: [
      '<div class="steerCamApp">',
        '<style>',
          '.steerCamApp{font-family:"Segoe UI",sans-serif;color:#e8e8ea;background:rgba(18,18,20,0.88);',
            'border-radius:7px;padding:9px 11px;box-sizing:border-box;width:100%;height:100%;overflow:auto;font-size:12px}',
          '.steerCamApp .sc-title{font-weight:700;font-size:14px;letter-spacing:.5px;color:#ff7a18}',
          '.steerCamApp .sc-title-row{display:flex;align-items:center;justify-content:space-between;margin-bottom:6px}',
          '.steerCamApp .sc-mod-en{display:flex;align-items:center;gap:5px;font-size:11px;font-weight:600;color:#9a9aa0;cursor:pointer}',
          '.steerCamApp .sc-mod-en input{accent-color:#ff7a18;margin:0}',
          '.steerCamApp .sc-mirror{display:flex;align-items:center;gap:7px;margin:0 0 8px;font-size:11px;color:#cfcfd4;cursor:pointer}',
          '.steerCamApp .sc-mirror input{accent-color:#ff7a18;margin:0}',
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
          '.steerCamApp .sc-presets-row{display:flex;align-items:center;gap:7px;margin-bottom:8px}',
          '.steerCamApp .sc-presets-lbl{flex:0 0 auto;font-weight:700;font-size:12px;color:#ff7a18}',
          '.steerCamApp .sc-dd{position:relative;flex:1 1 auto}',
          '.steerCamApp .sc-dd-head{width:100%;display:flex;justify-content:space-between;align-items:center;',
            'background:rgba(255,255,255,0.08);color:#e8e8ea;border:1px solid rgba(255,255,255,0.14);',
            'border-radius:4px;padding:4px 7px;font-size:11px;cursor:pointer}',
          '.steerCamApp .sc-dd-head:hover{background:rgba(255,255,255,0.16)}',
          '.steerCamApp .sc-dd-arr{color:#ff7a18;font-size:9px;margin-left:6px}',
          '.steerCamApp .sc-dd-list{position:absolute;top:calc(100% + 2px);left:0;right:0;z-index:20;',
            'background:rgba(28,28,32,0.98);border:1px solid rgba(255,255,255,0.18);border-radius:4px;overflow:hidden}',
          '.steerCamApp .sc-dd-opt{padding:5px 7px;font-size:11px;cursor:pointer}',
          '.steerCamApp .sc-dd-opt:hover{background:rgba(255,255,255,0.12)}',
          '.steerCamApp .sc-dd-opt.active{background:#ff7a18;color:#161616;font-weight:700}',
          '.steerCamApp .sc-row>b{flex:0 0 42px;text-align:right;color:#fff;font-variant-numeric:tabular-nums}',
          '.steerCamApp .sc-chk label{display:flex;align-items:center;gap:7px;cursor:pointer}',
          '.steerCamApp .sc-chk input{accent-color:#ff7a18}',
          '.steerCamApp.locked .sc-row{opacity:0.5}',
          '.steerCamApp.locked .sc-chk label{cursor:default}',
          '.steerCamApp .sc-row.sc-dim{opacity:0.45}',
          '.steerCamApp .sc-sec .sc-en{display:flex;align-items:center;justify-content:space-between}',
          '.steerCamApp .sc-sec .sc-en input{accent-color:#ff7a18;margin:0}',
          '.steerCamApp .sc-sec-name{display:flex;align-items:center;gap:6px;flex:1 1 auto;cursor:pointer;user-select:none}',
          '.steerCamApp .sc-tw{display:inline-block;font-size:9px;color:#ff7a18;transition:transform .15s ease}',
          '.steerCamApp .sc-tw.open{transform:rotate(90deg)}',
          '.steerCamApp .sc-off{opacity:0.4;pointer-events:none}',
          '.steerCamApp .sc-hint{font-size:10px;color:#9a9aa0;margin-top:6px}',
        '</style>',

        '<div class="sc-title-row">',
          '<span class="sc-title">SteerCam</span>',
          '<label class="sc-mod-en"><input type="checkbox" ng-model="modEnabled" ng-change="setMod(modEnabled)"><span>Enabled</span><md-tooltip ng-if="tips.modEnable" md-direction="bottom">{{tips.modEnable}}</md-tooltip></label>',
        '</div>',

        '<div class="sc-presets-row">',
          '<span class="sc-presets-lbl">Presets</span>',
          '<div class="sc-dd">',
            '<button class="sc-dd-head" ng-click="toggleDD(\'preset\')">{{preset}}<span class="sc-dd-arr">▾</span></button>',
            '<div class="sc-dd-list" ng-show="openDD===\'preset\'">',
              '<div class="sc-dd-opt" ng-repeat="p in presetNames" ng-class="{active: preset===p}" ng-click="choose(p); openDD=null">{{p}}</div>',
            '</div>',
          '</div>',
        '</div>',

        '<label class="sc-mirror"><input type="checkbox" ng-model="mirrorSeat" ng-change="setMirror(mirrorSeat)"> Driver seat side mirrors settings<md-tooltip ng-if="tips.mirror" md-direction="bottom">{{tips.mirror}}</md-tooltip></label>',

        '<div class="sc-sec"><div class="sc-en"><span class="sc-sec-name" ng-click="toggleCollapse(\'cam\')"><span class="sc-tw" ng-class="{open:!collapsed.cam}">▸</span>Camera settings override<md-tooltip ng-if="tips.cam" md-direction="bottom">{{tips.cam}}</md-tooltip></span><input type="checkbox" ng-model="cfg.camEnable" ng-change="setEnable(\'cam\',\'camEnable\',cfg.camEnable)" ng-disabled="locked"></div></div>',
        '<div class="sc-sec-body" ng-show="!collapsed.cam" ng-class="{\'sc-off\':!cfg.camEnable}">',
          '<div class="sc-row"><span>Forward Offset<md-tooltip ng-if="tips.camFwd" md-direction="right">{{tips.camFwd}}</md-tooltip></span>',
            '<input type="range" min="-0.5" max="0.5" step="0.01" ng-model="cfg.camFwd" ng-change="set(\'camFwd\', cfg.camFwd)" ng-disabled="locked">',
            '<b>{{cfg.camFwd}}m</b></div>',
          '<div class="sc-row"><span>Vertical Offset<md-tooltip ng-if="tips.camUp" md-direction="right">{{tips.camUp}}</md-tooltip></span>',
            '<input type="range" min="-0.5" max="0.5" step="0.01" ng-model="cfg.camUp" ng-change="set(\'camUp\', cfg.camUp)" ng-disabled="locked">',
            '<b>{{cfg.camUp}}m</b></div>',
          '<div class="sc-row"><span>Rotate L/R<md-tooltip ng-if="tips.camYaw" md-direction="right">{{tips.camYaw}}</md-tooltip></span>',
            '<input type="range" min="-45" max="45" step="1" ng-model="cfg.camYaw" ng-change="set(\'camYaw\', cfg.camYaw)" ng-disabled="locked">',
            '<b>{{cfg.camYaw}}°</b></div>',
          '<div class="sc-row"><span>Rotate D/U<md-tooltip ng-if="tips.camPitch" md-direction="right">{{tips.camPitch}}</md-tooltip></span>',
            '<input type="range" min="-45" max="45" step="1" ng-model="cfg.camPitch" ng-change="set(\'camPitch\', cfg.camPitch)" ng-disabled="locked">',
            '<b>{{cfg.camPitch}}°</b></div>',
          '<div class="sc-row"><span>Horizon lock<md-tooltip ng-if="tips.stableHorizon" md-direction="right">{{tips.stableHorizon}}</md-tooltip></span>',
            '<input type="range" min="0" max="100" step="1" ng-model="cfg.stableHorizon" ng-change="set(\'stableHorizon\', cfg.stableHorizon)" ng-disabled="locked">',
            '<b>{{cfg.stableHorizon}}%</b></div>',
          '<div class="sc-row"><span>FOV<md-tooltip ng-if="tips.camFov" md-direction="right">{{tips.camFov}}</md-tooltip></span>',
            '<input type="range" min="40" max="120" step="1" ng-model="cfg.camFov" ng-change="set(\'camFov\', cfg.camFov)" ng-disabled="locked">',
            '<b>{{cfg.camFov}}°</b></div>',
        '</div>',

        '<div class="sc-sec"><div class="sc-en"><span class="sc-sec-name" ng-click="toggleCollapse(\'steer\')"><span class="sc-tw" ng-class="{open:!collapsed.steer}">▸</span>Steering Input Pan<md-tooltip ng-if="tips.steer" md-direction="bottom">{{tips.steer}}</md-tooltip></span><input type="checkbox" ng-model="cfg.steerEnable" ng-change="setEnable(\'steer\',\'steerEnable\',cfg.steerEnable)" ng-disabled="locked"></div></div>',
        '<div class="sc-sec-body" ng-show="!collapsed.steer" ng-class="{\'sc-off\':!cfg.steerEnable}">',
          '<div class="sc-row"><span>Angle<md-tooltip ng-if="tips.angle" md-direction="right">{{tips.angle}}</md-tooltip></span>',
            '<input type="range" min="0" max="90" step="1" ng-model="cfg.angle" ng-change="set(\'angle\', cfg.angle)" ng-disabled="locked">',
            '<b>{{cfg.angle}}°</b></div>',
          '<div class="sc-row"><span>Steering range<md-tooltip ng-if="tips.reach" md-direction="right">{{tips.reach}}</md-tooltip></span>',
            '<input type="range" min="10" max="100" step="5" ng-model="cfg.reach" ng-change="set(\'reach\', cfg.reach)" ng-disabled="locked">',
            '<b>{{cfg.reach}}%</b></div>',
          '<div class="sc-row"><span>Stiffness<md-tooltip ng-if="tips.stiffness" md-direction="right">{{tips.stiffness}}</md-tooltip></span>',
            '<input type="range" min="1" max="40" step="1" ng-model="cfg.stiffness" ng-change="set(\'stiffness\', cfg.stiffness)" ng-disabled="locked">',
            '<b>{{cfg.stiffness}}</b></div>',
          '<div class="sc-row sc-chk"><label><input type="checkbox" ng-model="cfg.reverseSteer" ng-change="set(\'reverseSteer\', cfg.reverseSteer)" ng-disabled="locked"> Mirror turn direction when reversing<md-tooltip ng-if="tips.reverseSteer" md-direction="right">{{tips.reverseSteer}}</md-tooltip></label></div>',
          '<div class="sc-row" ng-show="cfg.reverseSteer"><span>Reverse angle<md-tooltip ng-if="tips.reverseAngle" md-direction="right">{{tips.reverseAngle}}</md-tooltip></span>',
            '<input type="range" min="0" max="90" step="1" ng-model="cfg.reverseAngle" ng-change="set(\'reverseAngle\', cfg.reverseAngle)" ng-disabled="locked">',
            '<b>{{cfg.reverseAngle}}°</b></div>',
          '<div class="sc-row" ng-show="cfg.reverseSteer"><span>Reverse blend<md-tooltip ng-if="tips.reverseTime" md-direction="right">{{tips.reverseTime}}</md-tooltip></span>',
            '<input type="range" min="0" max="3000" step="50" ng-model="cfg.reverseTime" ng-change="set(\'reverseTime\', cfg.reverseTime)" ng-disabled="locked">',
            '<b>{{cfg.reverseTime}}ms</b></div>',
          '<div class="sc-row sc-chk"><label><input type="checkbox" ng-model="cfg.speedFade" ng-change="set(\'speedFade\', cfg.speedFade)" ng-disabled="locked"> Fade in with speed<md-tooltip ng-if="tips.speedFade" md-direction="right">{{tips.speedFade}}</md-tooltip></label></div>',
          '<div class="sc-row" ng-show="cfg.speedFade"><span>Fade speed<md-tooltip ng-if="tips.fadeSpeed" md-direction="right">{{tips.fadeSpeed}}</md-tooltip></span>',
            '<input type="range" min="5" max="150" step="5" ng-model="cfg.fadeSpeed" ng-change="set(\'fadeSpeed\', cfg.fadeSpeed)" ng-disabled="locked">',
            '<b style="flex:0 0 64px">{{cfg.fadeSpeed}} km/h</b></div>',
          '<div class="sc-row" ng-show="cfg.speedFade"><span>Standstill turn<md-tooltip ng-if="tips.fadeFloor" md-direction="right">{{tips.fadeFloor}}</md-tooltip></span>',
            '<input type="range" min="0" max="100" step="5" ng-model="cfg.fadeFloor" ng-change="set(\'fadeFloor\', cfg.fadeFloor)" ng-disabled="locked">',
            '<b>{{cfg.fadeFloor}}%</b></div>',
        '</div>',

        '<div class="sc-sec"><div class="sc-en"><span class="sc-sec-name" ng-click="toggleCollapse(\'glance\')"><span class="sc-tw" ng-class="{open:!collapsed.glance}">▸</span>Blind-spot glance<md-tooltip ng-if="tips.glance" md-direction="bottom">{{tips.glance}}</md-tooltip></span><input type="checkbox" ng-model="cfg.glanceEnable" ng-change="setEnable(\'glance\',\'glanceEnable\',cfg.glanceEnable)" ng-disabled="locked"></div></div>',
        '<div class="sc-sec-body" ng-show="!collapsed.glance" ng-class="{\'sc-off\':!cfg.glanceEnable}">',
          '<div class="sc-row"><span>Left angle<md-tooltip ng-if="tips.glanceLeft" md-direction="right">{{tips.glanceLeft}}</md-tooltip></span>',
            '<input type="range" min="0" max="170" step="5" ng-model="cfg.glanceLeft" ng-change="set(\'glanceLeft\', cfg.glanceLeft)" ng-disabled="locked">',
            '<b>{{cfg.glanceLeft}}°</b></div>',
          '<div class="sc-row"><span>Right angle<md-tooltip ng-if="tips.glanceRight" md-direction="right">{{tips.glanceRight}}</md-tooltip></span>',
            '<input type="range" min="0" max="170" step="5" ng-model="cfg.glanceRight" ng-change="set(\'glanceRight\', cfg.glanceRight)" ng-disabled="locked">',
            '<b>{{cfg.glanceRight}}°</b></div>',
          '<div class="sc-row"><span>Glance time<md-tooltip ng-if="tips.glanceTime" md-direction="right">{{tips.glanceTime}}</md-tooltip></span>',
            '<input type="range" min="0" max="500" step="10" ng-model="cfg.glanceTime" ng-change="set(\'glanceTime\', cfg.glanceTime)" ng-disabled="locked">',
            '<b>{{cfg.glanceTime}}ms</b></div>',
          '<div class="sc-row"><span>Glance curve<md-tooltip ng-if="tips.glanceCurve" md-direction="right">{{tips.glanceCurve}}</md-tooltip></span>',
            '<div class="sc-dd">',
              '<button class="sc-dd-head" ng-click="toggleDD(\'curve\')" ng-disabled="locked">{{curveLabel(cfg.glanceCurve)}}<span class="sc-dd-arr">▾</span></button>',
              '<div class="sc-dd-list" ng-show="openDD===\'curve\'">',
                '<div class="sc-dd-opt" ng-repeat="o in curveOptions" ng-class="{active: cfg.glanceCurve===o.k}" ng-click="setCurve(o.k); openDD=null">{{o.l}}</div>',
              '</div>',
            '</div></div>',
          '<div class="sc-row"><span>Left offset<md-tooltip ng-if="tips.glanceOffsetLeft" md-direction="right">{{tips.glanceOffsetLeft}}</md-tooltip></span>',
            '<input type="range" min="-0.5" max="0.5" step="0.01" ng-model="cfg.glanceOffsetLeft" ng-change="set(\'glanceOffsetLeft\', cfg.glanceOffsetLeft)" ng-disabled="locked">',
            '<b>{{cfg.glanceOffsetLeft}}m</b></div>',
          '<div class="sc-row"><span>Right offset<md-tooltip ng-if="tips.glanceOffsetRight" md-direction="right">{{tips.glanceOffsetRight}}</md-tooltip></span>',
            '<input type="range" min="-0.5" max="0.5" step="0.01" ng-model="cfg.glanceOffsetRight" ng-change="set(\'glanceOffsetRight\', cfg.glanceOffsetRight)" ng-disabled="locked">',
            '<b>{{cfg.glanceOffsetRight}}m</b></div>',
          '<div class="sc-glance-btns">',
            '<button ng-class="{active: glanceSide===\'left\'}" ng-click="toggleGlance(\'left\')">Preview left</button>',
            '<button ng-class="{active: glanceSide===\'right\'}" ng-click="toggleGlance(\'right\')">Preview right</button>',
          '</div>',
          '<div class="sc-hint">Preview holds the glance so you can tune the angle. Needs the SteerCam view active (press C).</div>',
        '</div>',

        '<div class="sc-sec"><div class="sc-en"><span class="sc-sec-name" ng-click="toggleCollapse(\'speed\')"><span class="sc-tw" ng-class="{open:!collapsed.speed}">▸</span>Speed modifiers<md-tooltip ng-if="tips.speed" md-direction="bottom">{{tips.speed}}</md-tooltip></span><input type="checkbox" ng-model="cfg.speedModEnable" ng-change="setEnable(\'speed\',\'speedModEnable\',cfg.speedModEnable)" ng-disabled="locked"></div></div>',
        '<div class="sc-sec-body" ng-show="!collapsed.speed" ng-class="{\'sc-off\':!cfg.speedModEnable}">',
          '<div class="sc-row sc-chk"><label><input type="checkbox" ng-model="cfg.vertigo" ng-change="set(\'vertigo\', cfg.vertigo)" ng-disabled="locked"> Speed vertigo (FOV)<md-tooltip ng-if="tips.vertigo" md-direction="right">{{tips.vertigo}}</md-tooltip></label></div>',
          '<div class="sc-row" ng-class="{\'sc-dim\':!cfg.vertigo}"><span>FOV change<md-tooltip ng-if="tips.vertigoFov" md-direction="right">{{tips.vertigoFov}}</md-tooltip></span>',
            '<input type="range" min="0" max="40" step="1" ng-model="cfg.vertigoFov" ng-change="set(\'vertigoFov\', cfg.vertigoFov)" ng-disabled="locked || !cfg.vertigo">',
            '<b>{{cfg.vertigoFov}}°</b></div>',
          '<div class="sc-row" ng-class="{\'sc-dim\':!cfg.vertigo}"><span>Dolly depth<md-tooltip ng-if="tips.vertigoDolly" md-direction="right">{{tips.vertigoDolly}}</md-tooltip></span>',
            '<input type="range" min="0" max="1.5" step="0.01" ng-model="cfg.vertigoDolly" ng-change="set(\'vertigoDolly\', cfg.vertigoDolly)" ng-disabled="locked || !cfg.vertigo">',
            '<b>{{cfg.vertigoDolly}}m</b></div>',
          '<div class="sc-row sc-chk"><label><input type="checkbox" ng-model="cfg.speedRoll" ng-change="set(\'speedRoll\', cfg.speedRoll)" ng-disabled="locked"> Speed camera roll<md-tooltip ng-if="tips.speedRoll" md-direction="right">{{tips.speedRoll}}</md-tooltip></label></div>',
          '<div class="sc-row" ng-class="{\'sc-dim\':!cfg.speedRoll}"><span>Roll change<md-tooltip ng-if="tips.rollAngle" md-direction="right">{{tips.rollAngle}}</md-tooltip></span>',
            '<input type="range" min="0" max="20" step="0.5" ng-model="cfg.rollAngle" ng-change="set(\'rollAngle\', cfg.rollAngle)" ng-disabled="locked || !cfg.speedRoll">',
            '<b>{{cfg.rollAngle}}°</b></div>',
          '<div class="sc-row"><span>Speed range<md-tooltip ng-if="tips.speedRange" md-direction="right">{{tips.speedRange}}</md-tooltip></span>',
            '<input type="range" min="20" max="400" step="5" ng-model="cfg.speedRange" ng-change="set(\'speedRange\', cfg.speedRange)" ng-disabled="locked">',
            '<b style="flex:0 0 64px">{{cfg.speedRange}} km/h</b></div>',
        '</div>',

        '<div class="sc-hint" ng-show="locked">Default is locked. Switch to Custom to edit.</div>',
      '</div>'
    ].join(''),
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      // fallback list; replaced by the real (file-scanned) list once Lua answers
      scope.presetNames = ['Default', "Dev's Preset", 'Custom'];
      scope.preset = 'Default';
      scope.locked = true;
      scope.glanceSide = 'none';
      scope.modEnabled = true;   // global mod on/off (independent of preset lock)
      scope.mirrorSeat = true;   // global: mirror side-specific settings on RHD cars
      // Hover tooltips (md-tooltip). Add an entry to give a category/control a hint,
      // leave it out for none. UI text only -- not per-preset, so it lives here, not
      // in the preset JSONs. Keyed by category id / control; rows can be added later.
      scope.tips = {
        modEnable: '',
        mirror: 'Settings describe a left-hand-drive seat. In right-hand-drive cars; camera pan, glance angle, etc. auto-mirror so it feels the same.',
        cam: '',
        steer: 'Turns the view camera view based on steering input',
        glance: 'Snap the view to different angles. Bind keys in Options > Controls > Camera',
        speed: 'Optional immersive, speed-driven effects: FOV vertigo and steering-based camera roll. Off by default.',
        camFwd: '',
        camUp: '',
        camYaw: '',
        camPitch: '',
        stableHorizon: '0 = horizon banks fully with the car; 100 = stays level (eases off on steep banks). Same as the game\'s Lock-roll-to-horizon.',
        camFov: '',
        angle: 'How far the view turns at full steering lock.',
        reach: 'How much steering reaches the full angle. Lower = more reactive to small inputs.',
        stiffness: 'How quickly the camera moves. Higher = snappier.',
        reverseSteer: 'While reversing, mirror the turn the other way.',
        reverseAngle: '',
        reverseTime: 'How slowly camera eases between forward and reverse steering angle. Determined by movement vector and gear.',
        speedFade: 'Scale the camera pan by speed: none when stopped, full by Fade speed.',
        fadeSpeed: 'Speed at which the camera pan reaches full strength.',
        fadeFloor: 'How much of the camera pan is kept even at a standstill. 0 = none until moving.',
        glanceLeft: '',
        glanceRight: '',
        glanceTime: '',
        glanceCurve: 'Easing curve for the glance motion.',
        glanceOffsetLeft: '',
        glanceOffsetRight: '',
        vertigo: 'Widen the FOV as you speed up, with a matching forward dolly (the vertigo warp).',
        vertigoFov: 'Max extra FOV added by the time you reach the speed range.',
        vertigoDolly: 'Distance kept "pinned" by the counter-dolly. 0 = FOV only, no camera move.',
        speedRoll: 'Lean into corners from steering, growing with speed.',
        rollAngle: 'Max lean angle (at full steering and the speed range).',
        speedRange: 'Speed at which the speed effects reach full strength.'
      };
      // per-section twirl state; refreshed from each profile's enable flags on load
      scope.collapsed = { cam: false, steer: false, glance: false, speed: true };
      scope.openDD = null;   // which custom dropdown is open ('preset' | 'curve' | null)
      scope.curveOptions = [
        { k: 'Exponential', l: 'Exponential (native)' },
        { k: 'Linear', l: 'Linear' },
        { k: 'S-curve', l: 'S-curve' },
        { k: 'Ease1', l: 'Ease1' },
        { k: 'Ease2', l: 'Ease2' }
      ];
      scope.curveLabel = function (k) {
        for (var i = 0; i < scope.curveOptions.length; i++) {
          if (scope.curveOptions[i].k === k) { return scope.curveOptions[i].l; }
        }
        return k;
      };
      scope.toggleDD = function (n) { scope.openDD = (scope.openDD === n) ? null : n; };

      // header text toggles the twirl only; the checkbox toggles enable
      scope.toggleCollapse = function (sec) { scope.collapsed[sec] = !scope.collapsed[sec]; };

      // section enable checkbox: toggle the feature, and auto-collapse when turning
      // it OFF. Turning it back ON never auto-expands (open it via the header).
      scope.setEnable = function (sec, key, val) {
        scope.set(key, val);
        if (!val) { scope.collapsed[sec] = true; }
      };

      // global mod on/off; works on any profile (not gated by the preset lock)
      scope.setMod = function (v) {
        bngApi.engineLua('if steerCam then steerCam.setEnabled(' + (v ? 'true' : 'false') + ') end');
      };

      // global driver-seat mirroring toggle (also independent of the preset lock)
      scope.setMirror = function (v) {
        bngApi.engineLua('if steerCam then steerCam.setMirror(' + (v ? 'true' : 'false') + ') end');
      };
      scope.cfg = {
        camEnable: true, camFwd: 0, camUp: 0, camYaw: 0, camPitch: 0, camFov: 65, stableHorizon: 0,
        steerEnable: true,
        angle: 18, reach: 35, stiffness: 15, reverseSteer: false, reverseAngle: 9, reverseTime: 500, speedFade: false, fadeSpeed: 30, fadeFloor: 0,
        glanceEnable: true,
        glanceLeft: 115, glanceRight: 115, glanceTime: 120, glanceCurve: 'Exponential',
        glanceOffsetLeft: 0.10, glanceOffsetRight: 0.10,
        speedModEnable: true,
        vertigo: false, vertigoFov: 12, vertigoDolly: 0.30, speedRoll: false, rollAngle: 5, speedRange: 160
      };

      function pushOne(key, val) {
        if (typeof val === 'boolean') {
          bngApi.engineLua("if steerCam then steerCam.set('" + key + "', " + (val ? 'true' : 'false') + ") end");
        } else if (typeof val === 'string') {
          bngApi.engineLua("if steerCam then steerCam.set('" + key + "', '" + val + "') end");
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

      // pull the file-scanned preset list (bundled + user-dropped .json files)
      function loadPresetNames() {
        bngApi.engineLua('steerCam and steerCam.getPresetNames() or nil', function (names) {
          if (!names) { return; }
          var arr = [];
          if (Object.prototype.toString.call(names) === '[object Array]') {
            arr = names.slice();
          } else if (typeof names === 'object') {
            for (var k in names) { if (names.hasOwnProperty(k)) { arr.push(names[k]); } }
          }
          if (arr.length) {
            scope.$evalAsync(function () { scope.presetNames = arr; });
          }
        });
      }

      function load() {
        loadPresetNames();
        bngApi.engineLua('steerCam and steerCam.getCfg() or nil', function (cfg) {
          if (cfg && typeof cfg === 'object') {
            scope.$evalAsync(function () {
              for (var k in cfg) {
                if (scope.cfg.hasOwnProperty(k)) { scope.cfg[k] = cfg[k]; }
              }
              if (cfg.preset) { scope.preset = cfg.preset; }
              scope.locked = (scope.preset !== 'Custom');
              if (typeof cfg.modEnabled === 'boolean') { scope.modEnabled = cfg.modEnabled; }
              if (typeof cfg.mirrorSeat === 'boolean') { scope.mirrorSeat = cfg.mirrorSeat; }
              // disabled sections start collapsed; enabled ones start open
              scope.collapsed = {
                cam: !scope.cfg.camEnable,
                steer: !scope.cfg.steerEnable,
                glance: !scope.cfg.glanceEnable,
                speed: !scope.cfg.speedModEnable
              };
            });
          }
        });
        syncGlance();
      }

      // pick a preset (escape any apostrophe, e.g. "Dev's Preset", for the Lua call)
      scope.choose = function (name) {
        var safe = name.replace(/'/g, "\\'");
        bngApi.engineLua("if steerCam then steerCam.setPreset('" + safe + "') end");
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

      // pick a glance easing curve (button group; native <select> doesn't open in the UI)
      scope.setCurve = function (name) {
        if (scope.locked) { return; }
        scope.cfg.glanceCurve = name;
        pushOne('glanceCurve', name);
      };

      // close an open custom dropdown when clicking/tapping anywhere outside it
      function ddOutside(e) {
        if (!scope.openDD) { return; }
        var n = e.target;
        while (n) {
          if (n.classList && n.classList.contains('sc-dd')) { return; } // inside a dropdown
          n = n.parentNode;
        }
        scope.$applyAsync(function () { scope.openDD = null; });
      }
      document.addEventListener('mousedown', ddOutside, true);
      scope.$on('$destroy', function () { document.removeEventListener('mousedown', ddOutside, true); });

      element.ready(function () {
        load();
        setTimeout(load, 600);
      });
    }
  };
}]);
