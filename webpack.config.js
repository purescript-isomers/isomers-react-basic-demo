module.exports = {
  entry: './src/App.Client.js',
  mode: 'development',
  devServer:{
    port:3001,
    contentBase: __dirname + "/static.js",
    compress: true,
    hot:true
  },
  output: {
    path: __dirname + '/static',
    filename: 'App.Client.js',
  },
};
