for REPO in bear5 bear6 bear-gemini bear-github bear-services bear-services-hds bear-stats bear-xero bear_x12 prex-cerner prex-idology prex-saaspass prex-surescripts trip-reporter; do                        
  echo "---$REPO---"
    aws ecr describe-images --repository-name "$REPO" --region us-west-1 --query 'imageDetails[*].imageTags[]' --output table 2>/dev/null || echo "  (no images)"                                                
  echo ""                                                                                                                                                                                                      
done         
