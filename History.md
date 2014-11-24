0.1.3 / 2014-11-24
==================
  + Added dynamic partial view by node server render. But must be use def.model. Render: res.render('index', {title: 'Welcome', partialPath: 'partial'}); In template: {{#def.include(def.model.partialPath, {title: 'The partial'}) }}

0.1.2 / 2013-05-28
==================
  + Added ability to include templates from the default views directory using a path like '~/forms/login'. Note: view engine must be set by passing in a reference to the app e.g. app.engine("def", dotemc.init({"app": app}).__express)
  + Added ability to swap out cache manager for a custom implementation.


0.1.1 / 2013-05-24
==================
  * Re-compiled coffee script with v1.6.2... I think I published the npm module with the wrong .js file... oops!

0.1.0 / 2013-02-09
==================

  * Initial release
