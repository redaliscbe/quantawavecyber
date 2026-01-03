(function(){
  function onLoad(){
    var spinner = document.getElementById('spinner');
    if(spinner){
      spinner.classList.remove('show');
      spinner.setAttribute('aria-hidden','true');
    }
    if(window.WOW && typeof WOW === 'function'){ try{ new WOW().init(); }catch(e){} }
  }
  if(document.readyState === 'complete') onLoad(); else window.addEventListener('load', onLoad);
})();