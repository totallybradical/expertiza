require 'rails_helper'

describe Answer do

	describe "#test get total score" do
		let!(:questionnaire) {create(:questionnaire)}
		let!(:question1) {create(:question,:questionnaire => questionnaire,:weight=>1)}
		let!(:question2) {create(:question,:questionnaire => questionnaire,:weight=>2)}
		let!(:response_record) {create(:response_record,:id => 1)}
			
		it "returns total score when required conditions are met" do
			# stub for ScoreView.find_by_sql to revent prevent unit testing sql db queries
			ScoreView.stub(:find_by_sql).and_return([double("scoreview",weighted_score: 20,sum_of_weights: 5,q1_max_question_score: 4)])
			Answer.stub(:where).and_return([double("row1",question_id: 1,answer: "1")])
			expect(Answer.get_total_score(response: [response_record], questions: [question1])).to be 100.0
			#calculation = (weighted_score / (sum_of_weights * max_question_score)) * 100
			# 4.0
		end

		it "returns total score when one answer is nil for scored question and its weight gets removed from sum_of_weights" do
			ScoreView.stub(:find_by_sql).and_return([double("scoreview",weighted_score: 20,sum_of_weights: 5,q1_max_question_score: 4)])
			Answer.stub(:where).and_return([double("row1",question_id: 1,answer: nil)])
			expect(Answer.get_total_score(response: [response_record], questions: [question1])).to be_within(0.01).of(125.0)
		end			

		it "returns -1 when answer is nil for scored question which makes sum of weights = 0" do
			ScoreView.stub(:find_by_sql).and_return([double("scoreview",weighted_score: 20,sum_of_weights: 1,q1_max_question_score: 5)])
			Answer.stub(:where).and_return([double("row1",question_id: 1,answer: nil)])
			expect(Answer.get_total_score(response: [response_record], questions: [question1])).to be -1.0
		end

		it "returns -1 when weighted_score of questionnaireData is nil" do
			ScoreView.stub(:find_by_sql).and_return([double("scoreview",weighted_score: nil,sum_of_weights: 5,q1_max_question_score: 5)])
			Answer.stub(:where).and_return([double("row1",question_id: 1,answer: nil)])
			expect(Answer.get_total_score(response: [response_record], questions: [question1])).to be -1.0
		end

		it "checks if submission_valid? is called" do
			ScoreView.stub(:find_by_sql).and_return([double("scoreview",weighted_score: nil,sum_of_weights: 5,q1_max_question_score: 5)])
			Answer.stub(:where).and_return([double("row1",question_id: 1,answer: nil)])
			expect(Answer).to receive(:submission_valid?)			
			Answer.get_total_score(response: [response_record], questions: [question1])
			
		end
	end

	describe "#test" do
	
		it "returns nil if list of assessments is empty" do
			assessments=[]
			#Answer.instance_variable_set(:@invalid,1)
			Answer.stub(:get_total_score).and_return(100.0)
			scores=Answer.compute_scores(assessments, [:question1])
			expect(scores[:max]).to be nil
			expect(scores[:min]).to be nil
			expect(scores[:avg]).to be nil
		end

		it "returns scores when a single valid assessment of total score 100 is give" do
			response1 = double("respons1")
			assessments=[response1]
			Answer.instance_variable_set(:@invalid,0)
			total_score=100.0
			Answer.stub(:get_total_score).and_return(total_score)
			scores=Answer.compute_scores(assessments, [:question1])
			expect(scores[:max]).to be total_score
			expect(scores[:min]).to be total_score
			expect(scores[:avg]).to be total_score
		end

		it "returns scores when two valid assessments of total scores 80 and 100 are given" do
			response1 = double("respons1")
			response2 = double("respons2")
			assessments=[response1,response2]
			Answer.instance_variable_set(:@invalid,0)
			total_score1=100.0
			total_score2=80.0
			Answer.stub(:get_total_score).and_return(total_score1,total_score2)
			scores=Answer.compute_scores(assessments, [:question1])
			expect(scores[:max]).to be total_score1
			expect(scores[:min]).to be total_score2
			expect(scores[:avg]).to be (total_score1+total_score2)/2
		end
		
		it "returns scores when an invalid assessments is given" do
			response1 = double("respons1")
			assessments=[response1]
			Answer.instance_variable_set(:@invalid,1)
			total_score=100.0
			Answer.stub(:get_total_score).and_return(total_score)
			scores=Answer.compute_scores(assessments, [:question1])
			expect(scores[:max]).to be total_score
			expect(scores[:min]).to be total_score
			expect(scores[:avg]).to be 0
		end
	end
end
