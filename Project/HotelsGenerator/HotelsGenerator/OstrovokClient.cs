using System;
using System.Net.Http;

namespace HotelsGenerator
{
    public class OstrovokClient : HttpClient
    {
        public void SetHeaders(String headers)
        {
            foreach (var header in headers.Split('\n'))
            {
                var splits = header.Split(new[] { ": " }, StringSplitOptions.None);
                DefaultRequestHeaders.Add(splits[0].Trim(), splits[1].Trim());
            }
        }
    }
}
